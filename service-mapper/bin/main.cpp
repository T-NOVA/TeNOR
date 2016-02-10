// Copyright 2014-2016 Universita' degli studi di Milano
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// -----------------------------------------------------
//
// Authors:
//     Alessandro Petrini (alessandro.petrini@unimi.it)
//
// -----------------------------------------------------
//
// This software uses jsoncons library by Daniel A. Parker under Boost Software License
// https://github.com/danielaparker/jsoncons
//
// -----------------------------------------------------
//

/*	The service mapper application is composed by a ruby app microservice and a C++ application
*	(from now on, referred as "binary app").
*	The workflow goes briefly like this:
*	- the ruby app is called by the Orchestrator and its tasks are mainly network related: it scans
*	and validate the allocation request and calls all the other microservices required to collect
*	all the information needed by the mapper algorithm, i.e., network infrastructure status,
*	network service requirements and topology, etc.
*	- all the data collected by the ruby app are saved on several files in json format in the bin/workspace
*	directory: these files are, for now, named NI.json, which contains data regarding the Network Infrastructure,
*	NS.json (data regarding the Network Service to be allocated and the composing VNFs); NS.json also stores optional
*	parameters to be passed to the solver (they may be moved to a pref.json file later in the development stage).
*	- the ruby app in turn invokes the binary app by making a system call and passing it all the files
*	collected so far. This system call is SYNCHRONOUS;
*	- the binary app scans the json files and converts them in mpl language, as required by the solver;
*	- GLPK solver is invoked and its solution is converted in json format and returned to the ruby app;
*	- ruby app returns the allocation response to the Orchestrator.
*
*	Current status of the whole application (24/sep/2015): as invoked by the Orchestrator, the ruby app queries both
*	IR and NS APIs to grab the essential data for the solution of the problem and saves it in NI.json + NS.json,
*	which in turn are passed to the binary app that parses them in order to build the required .dat files in MPL
*	format. As now, data is divided in three .dat files:
*	- NI_generated.dat: it contains the snapshot of the Network Infrastructure, i.e. list of PoP and its connection
*	topology, as well as additional information of each PoP and each link between them, i.e. computing
*	power and capabilities, bandwidth and dealy of network connection, etc.
*	- NS_generated.dat: it contains the description of the Network Service and its requirement, i.e., list of
*	Virtual	Network Functions and their connection graph, as well as minimal hardware and b/w requirements.
*	- pref_generated.dat: it contains a list of variables that are not strictly realted to the NI or NS, but are
*	used by the solver for adapting the solution to any kind of condition specified by the customer (i.e.
*	placing a VNF into a certain and unmovable PoP) or by the network status / flavour / service
*	characteristics by steering the solution for meeting those requirements (i.e. by preferring delay
*	minimization instead of PoP spreading).
*	Then, the GLPK API are invoked in order to build the workspace and problem; if everything goes well, the solver
*	is invoked.
*	A MapperResponse.json file is built at the end of the solver operations, regardless of its response: if a valid
*	map has been found, the json file contains the actual map (check MapperResponse.json for the syntax),
*	otherwise it will contain a brief description of the error.
*
*	At the very end, the ruby app takes back the control and returns the MapperResponse.json the Orchestrator
*/

#define DEBUGPRINT

#include "jsoncons/json.hpp"
#include <unordered_map>

#ifdef __unix__
#include <glpk.h>
#define BINPATH "bin/"
#endif
#ifdef _WIN32
#include <glpk/glpk.h>
#define BINPATH ""
#endif

#include <iostream>
#include <fstream>
#include <string>
#include <array>
#include <ctime>

// Builds NI.dat from NI.json
int build_NIdat( const std::string filename, jsoncons::json * const pop_link_detail_array, jsoncons::json * const pop_id_array, const jsoncons::json * const vnf_id_array, const jsoncons::json * const ns_connection_points ) {
	std::string			NI_inFilename 		= filename;
	std::string			NI_outFilename		= BINPATH + std::string( "workspace/NI_generated.dat" );
	std::ofstream		NI_outFile;
	jsoncons::json		NI_json;
	jsoncons::json		pop_detail_array( jsoncons::json::an_array );
	jsoncons::json		pop_link_id_array( jsoncons::json::an_array );
	jsoncons::json		aggregate_resources_json;
	// temp variables
	std::string			source_node, destination_node, link_available_bw, link_roundtrip, temp_pop_id;

	// open the NI.json and parse it
	NI_outFile.open( NI_outFilename.c_str(), std::ios::out );
	NI_json = jsoncons::json::parse_file( NI_inFilename );

	// Build several json objects from the parsed input file
	*pop_id_array				= NI_json.get( "PoP_id" );
	pop_detail_array			= NI_json.get( "PoP_detail" );
	pop_link_id_array			= NI_json.get( "PoP_link_id" );
	*pop_link_detail_array		= NI_json.get( "PoP_link_detail" );
	aggregate_resources_json	= NI_json.get( "PoP_aggregate_resources" );

	// # HACK 1 #
	// If NI does not contain any link, GLPK may crash since the model requires the objective function to be divided
	// by total_delay and tot_linkusage that in this case are equal to 0...
	// To prevent this, we create a fake link whose source and destination is the first node in the pop_id_array, and
	// whose LinkDelay and LinkUsage are abnormally high.
	if (pop_link_id_array.size() == 0) {
		pop_link_id_array.add( "/pop/link/fakelink" );
		jsoncons::json fakelink_detail = jsoncons::json();
		jsoncons::json fakelink_detail_attributes = jsoncons::json();
		fakelink_detail["identifier"] = std::string( "/pop/link/fakelink" );
		fakelink_detail["source"] = pop_id_array->at( 0 ).as<std::string>();
		fakelink_detail["target"] = pop_id_array->at( 0 ).as<std::string>();
		fakelink_detail_attributes["occi.epa.pop.bw_Gps"] = std::string( "100.0" );
		fakelink_detail_attributes["occi.epa.pop.bw_util_Gps"] = std::string( "100.0" );
		fakelink_detail_attributes["occi.epa.pop.roundtrip_time_sec"] = std::string( "1.0" );
		fakelink_detail["attributes"] = fakelink_detail_attributes;
		pop_link_detail_array->add( fakelink_detail );
	}

	// Begin write NI_generated.dat
	// data;
	NI_outFile << "  /* NI generata da NI.json */" << std::endl;
	NI_outFile << std::endl;
	NI_outFile << "data;" << std::endl;
	NI_outFile << std::endl;

	// set NInodes
	NI_outFile << "set NInodes := " << std::endl;
	for (auto it = pop_id_array->begin_elements(); it != pop_id_array->end_elements(); ++it) {
		NI_outFile << "\"" << it->as<std::string>() << "\"" << std::endl;
	}
	NI_outFile << ";" << std::endl << std::endl;

	// set NIlinks
	NI_outFile << "set NIlinks := " << std::endl;
	for (auto it = pop_link_detail_array->begin_elements(); it != pop_link_detail_array->end_elements(); ++it) {
		source_node = it->get( "source" ).as<std::string>();
		destination_node = it->get( "target" ).as<std::string>();
		NI_outFile << "(\"" << source_node << "\", \"" << destination_node << "\")" << std::endl;
	}
	NI_outFile << ";" << std::endl << std::endl;

	//set NT
	NI_outFile << "set NT := cpu ram hdd;" << std::endl << std::endl;

	// set LT
	NI_outFile << "set LT := bw;" << std::endl << std::endl;

	// param: ResourceNodeCapacity
	// Note: we set negative resources values (due to overcommitting) to 0.
	NI_outFile << "param: 		ResourceNodeCapacity :=" << std::endl;
	for (auto it = pop_id_array->begin_elements(); it != pop_id_array->end_elements(); ++it) {
		temp_pop_id = it->as<std::string>();
		int temp_aggregate_cpu = aggregate_resources_json[temp_pop_id]["aggregate_cpus"].as<int>();
		int temp_aggregate_ram = aggregate_resources_json[temp_pop_id]["aggregate_ram"].as<int>();
		int temp_aggregate_hdd = aggregate_resources_json[temp_pop_id]["aggregate_hdd"].as<int>();

		if (temp_aggregate_cpu >= 0)
			NI_outFile << "\"" << temp_pop_id << "\" cpu " << aggregate_resources_json[temp_pop_id]["aggregate_cpus"].as<std::string>() << std::endl;
		else
			NI_outFile << "\"" << temp_pop_id << "\" cpu 0" << std::endl;

		if (temp_aggregate_ram >= 0)
			NI_outFile << "\"" << temp_pop_id << "\" ram " << aggregate_resources_json[temp_pop_id]["aggregate_ram"].as<std::string>() << std::endl;
		else
			NI_outFile << "\"" << temp_pop_id << "\" ram 0" << std::endl;

		if (temp_aggregate_hdd >= 0)
			NI_outFile << "\"" << temp_pop_id << "\" hdd " << aggregate_resources_json[temp_pop_id]["aggregate_hdd"].as<std::string>() << std::endl;
		else
			NI_outFile << "\"" << temp_pop_id << "\" hdd 0" << std::endl;
	}
	NI_outFile << ";" << std::endl << std::endl;

	// param: ResourceLinkCapacity
	NI_outFile << "param: 		ResourceLinkCapacity :=" << std::endl;
	for (auto it = pop_link_detail_array->begin_elements(); it != pop_link_detail_array->end_elements(); ++it) {
		source_node = it->get( "source" ).as<std::string>();
		destination_node = it->get( "target" ).as<std::string>();
		std::string bw = it->get( "attributes" ).get( "occi.epa.pop.bw_Gps" ).as<std::string>();
		std::string bw_ut = it->get( "attributes" ).get( "occi.epa.pop.bw_util_Gps" ).as<std::string>();
		// It may throw an exception if not pure numbers
		NI_outFile << "\"" << source_node << "\" \"" << destination_node << "\" bw " << atof( bw.c_str() ) - atof( bw_ut.c_str() ) << std::endl;
	}
	NI_outFile << ";" << std::endl << std::endl;

	// param: LinkDelay
	NI_outFile << "param: 		LinkDelay :=" << std::endl;
	for (auto it = pop_link_detail_array->begin_elements(); it != pop_link_detail_array->end_elements(); ++it) {
		source_node = it->get( "source" ).as<std::string>();
		destination_node = it->get( "target" ).as<std::string>();
		link_roundtrip = it->get( "attributes" ).get( "occi.epa.pop.roundtrip_time_sec" ).as<std::string>();
		NI_outFile << "\"" << source_node << "\" \"" << destination_node << "\" " << link_roundtrip << std::endl;
	}
	NI_outFile << ";" << std::endl << std::endl;

	// param: c
	// --TODO--: As now, the allocation costs are randomly generated at runtime.
	NI_outFile << "param:		c :=" << std::endl;
	for (auto it = pop_id_array->begin_elements(); it != pop_id_array->end_elements(); ++it) {
		for (auto it2 = vnf_id_array->begin_elements(); it2 != vnf_id_array->end_elements(); ++it2) {
			int cost = 100 + rand() % 100 - 50;
			NI_outFile << "\"" << it2->as<std::string>() << "\" \"" << it->as<std::string>() << "\" " << cost << std::endl;
		}
	}
	for (auto it = pop_id_array->begin_elements(); it != pop_id_array->end_elements(); ++it) {
		for (auto it2 = ns_connection_points->begin_elements(); it2 != ns_connection_points->end_elements(); ++it2) {
			//int cost = 100 + rand() % 100 - 50;
			NI_outFile << "\"/" << it2->as<std::string>() << "\" \"" << it->as<std::string>() << "\" 0" << std::endl;
		}
	}
	/*
	NI_outFile << "param:		c :=" << std::endl;
	NI_outFile << (*vnf_id_array)[0] << " \"" << (*pop_id_array)[0].as<std::string>() << "\" 100" << std::endl;
	NI_outFile << (*vnf_id_array)[1] << " \"" << (*pop_id_array)[0].as<std::string>() << "\" 120" << std::endl;
	NI_outFile << (*vnf_id_array)[2] << " \"" << (*pop_id_array)[0].as<std::string>() << "\" 130" << std::endl;
	NI_outFile << (*vnf_id_array)[0] << " \"" << (*pop_id_array)[1].as<std::string>() << "\" 80" << std::endl;
	NI_outFile << (*vnf_id_array)[1] << " \"" << (*pop_id_array)[1].as<std::string>() << "\" 110" << std::endl;
	NI_outFile << (*vnf_id_array)[2] << " \"" << (*pop_id_array)[1].as<std::string>() << "\" 150" << std::endl;
	NI_outFile << (*vnf_id_array)[0] << " \"" << (*pop_id_array)[2].as<std::string>() << "\" 90" << std::endl;
	NI_outFile << (*vnf_id_array)[1] << " \"" << (*pop_id_array)[2].as<std::string>() << "\" 125" << std::endl;
	NI_outFile << (*vnf_id_array)[2] << " \"" << (*pop_id_array)[2].as<std::string>() << "\" 135" << std::endl;
	*/
	NI_outFile << ";" << std::endl << std::endl;

	NI_outFile << "end;" << std::endl;

	NI_outFile.close();

	return 0;
}

int build_NSdat( const std::string filename, jsoncons::json * const vnf_id_array, jsoncons::json * const NS_json, jsoncons::json * const ns_connection_points ) {
	std::string			NS_inFilename = filename;
	std::string			NS_outFilename = BINPATH + std::string( "workspace/NS_generated.dat" );
	std::string			source_tmp, dest_tmp, link_id_tmp;
	std::ofstream		NS_outFile;
	jsoncons::json		vnf_req( jsoncons::json::an_array );
	jsoncons::json		ns_virtual_links( jsoncons::json::an_array );
	jsoncons::json		ns_nfp( jsoncons::json::an_array );
	jsoncons::json		tmp_graph( jsoncons::json::an_array );
	std::unordered_map <std::string, std::string> tmp_links = std::unordered_map <std::string, std::string>();

	// open and parse NS.json
	NS_outFile.open( NS_outFilename.c_str(), std::ios::out );
	*NS_json = jsoncons::json::parse_file( NS_inFilename );

	// Build several json objects from the parsed input file
	*vnf_id_array = NS_json->get( "vnf_id" );
	vnf_req = NS_json->get( "vnf_req" );
	*ns_connection_points = NS_json->get( "connection_points" );
	ns_virtual_links = NS_json->get( "virtual_links" );
	ns_nfp = NS_json->get( "network_forwarding_paths" );

	// Begin write NS_generated.dat
	NS_outFile << "  /* NS generated from " << filename << " */" << std::endl;
	NS_outFile << std::endl;
	NS_outFile << "data;" << std::endl;
	NS_outFile << std::endl;

	// VNFnodes
	NS_outFile << "set VNFnodes := " << std::endl;
	for (auto it = ns_connection_points->begin_elements(); it != ns_connection_points->end_elements(); ++it) {
		NS_outFile << "\"/" << it->as<std::string>() << "\"" << std::endl;
	}
	for (auto it = vnf_id_array->begin_elements(); it != vnf_id_array->end_elements(); ++it) {
		NS_outFile << "\"" << it->as<std::string>() << "\"" << std::endl;
	}
	NS_outFile << ";" << std::endl << std::endl;

	// vnffgd
	// we strip the connection point id by the connection point names; we're only interested in the
	// VNF name which owns these connection points
	int temp_idx_src, temp_idx_dst;
	NS_outFile << "set NSlinks := ";
	for (auto it = ns_virtual_links.begin_elements(); it != ns_virtual_links.end_elements(); ++it) {
		std::string tmp_outstring = std::string();
		link_id_tmp = it->get("virtual_link_id").as<std::string>();
		source_tmp = it->get("source").as<std::string>();
		dest_tmp   = it->get("destination").as<std::string>();
		temp_idx_src = source_tmp.find_first_of( ":", 0 );
		temp_idx_dst = dest_tmp.find_first_of( ":", 0 );
		tmp_outstring = tmp_outstring + "(";
		if ( temp_idx_src == -1 )
			tmp_outstring = tmp_outstring + "\"/" + source_tmp + "\",";
		else
			tmp_outstring = tmp_outstring +  "\"/" + source_tmp.substr( 0, temp_idx_src ) + "\",";
		if ( temp_idx_dst == -1 )
			tmp_outstring = tmp_outstring + "\"/" + dest_tmp + "\") ";
		else
			tmp_outstring = tmp_outstring +  "\"/" + dest_tmp.substr( 0, temp_idx_dst ) + "\") ";
		NS_outFile << tmp_outstring;

		// save the generated string for later reuse (during printout of the path)
		tmp_links.emplace( link_id_tmp, tmp_outstring );
	}
	NS_outFile << ";" << std::endl << std::endl;

	// Number of paths (indexes!)
	NS_outFile << "set IndexDelayPaths :=";
	for (unsigned int i = 0; i < ns_nfp.size(); i++)
		NS_outFile  << " " << i + 1 ;
	NS_outFile << ";" << std::endl << std::endl;


	// Definition of each path; we reuse the tmp_links unordered_map
	unsigned int tmp_link_idx = 0;
	for (auto it = ns_nfp.begin_elements(); it != ns_nfp.end_elements(); ++it) {
		tmp_graph = it->get("nfp_graph");
		NS_outFile << "set PD[" << ++tmp_link_idx << "] :=";
		for (auto it02 = tmp_graph.begin_elements(); it02 != tmp_graph.end_elements(); ++it02 ) {
			NS_outFile << " " << tmp_links[it02->as<std::string>()];
		}
		NS_outFile << ";" << std::endl;
	}
	NS_outFile << std::endl;

	// Resource node requirements
	// Also, fake nodes have 0 resource demands
	NS_outFile << "param: 			ResourceNodeDemand :=" << std::endl;
	for (auto it = vnf_req.begin_elements(); it != vnf_req.end_elements(); ++it) {
		std::string temp_vnf_id = it->get("vnf_id").as<std::string>();
		NS_outFile << "\"" << temp_vnf_id << "\" cpu " << it->get("req_vcpus").as<std::string>() << std::endl;
		NS_outFile << "\"" << temp_vnf_id << "\" ram " << it->get("req_ram").as<std::string>() << std::endl;
		NS_outFile << "\"" << temp_vnf_id << "\" hdd " << it->get("req_hdd").as<std::string>() << std::endl;
	}
	for (auto it = ns_connection_points->begin_elements(); it != ns_connection_points->end_elements(); ++it) {
		NS_outFile << "\"/" << it->as<std::string>() << "\" cpu 0" << std::endl;
		NS_outFile << "\"/" << it->as<std::string>() << "\" ram 0.0" << std::endl;
		NS_outFile << "\"/" << it->as<std::string>() << "\" hdd 0.0" << std::endl;
	}
	NS_outFile << ";" << std::endl << std::endl;


	// Resource link requirements
	// same name stripping as before
	NS_outFile << "param: 			ResourceLinkDemand :=" << std::endl;
	for (auto it = ns_virtual_links.begin_elements(); it != ns_virtual_links.end_elements(); ++it) {
		source_tmp = it->get("source").as<std::string>();
		dest_tmp   = it->get("destination").as<std::string>();
		temp_idx_src = source_tmp.find_first_of( ":", 0 );
		temp_idx_dst = dest_tmp.find_first_of( ":", 0 );
		if ( temp_idx_src == -1 )
			source_tmp = "\"/" + source_tmp + "\"";
		else
			source_tmp = "\"/" + source_tmp.substr( 0, temp_idx_src ) + "\"";
		if ( temp_idx_dst == -1 )
			dest_tmp = "\"/" + dest_tmp + "\"";
		else
			dest_tmp = "\"/" + dest_tmp.substr( 0, temp_idx_dst ) + "\"";

		NS_outFile << source_tmp << " " << dest_tmp << " bw " << it->get("root_requirements").as<std::string>() << std::endl;
	}
	NS_outFile << ";" << std::endl << std::endl;


	// Mawimum allowed delay per path
	// hardwired in the solutor (still unused in T-Nova)
	tmp_link_idx = 0;
	NS_outFile << "param: 		MaxDelay :=" << std::endl;
	for (unsigned int i = 0; i < ns_nfp.size(); i++)
		NS_outFile  << i + 1 << " 10.0" << std::endl;
	NS_outFile << ";" << std::endl << std::endl;


	// End of NS_generated.dat
	NS_outFile << "end;" << std::endl << std::endl;

	NS_outFile.close();

	return 0;

}

int build_prefdat( const jsoncons::json * const pop_id_array, const jsoncons::json * const vnf_id_array, const jsoncons::json * const NS_json, const jsoncons::json * const ns_connection_points ) {
	std::string			pref_outFilename = BINPATH + std::string( "workspace/pref_generated.dat" );
	std::ofstream		pref_outFile;

	pref_outFile.open( pref_outFilename.c_str(), std::ios::out );

	// comment
	pref_outFile << "   /* preference file automatically generated */" << std::endl << std::endl;

	// data;
	pref_outFile << "data;" << std::endl << std::endl;

	// alpha, beta, gamma
	if (NS_json->has_member( "Alpha" ))
		pref_outFile << "param alpha := " << NS_json->get( "Alpha" ).as<std::string>() << ";" << std::endl;
	else
		pref_outFile << "param alpha := 0.7;" << std::endl;		// valore negativo: aumenta spread di vnf sui PoP
	if (NS_json->has_member( "Beta" ))
		pref_outFile << "param beta := " << NS_json->get( "Beta" ).as<std::string>() << ";" << std::endl;
	else
		pref_outFile << "param beta  := 0.2;" << std::endl;			// valore negativo: aumenta consumo dei link
	if (NS_json->has_member( "Gamma" ))
		pref_outFile << "param gamma := " << NS_json->get( "Gamma" ).as<std::string>() << ";" << std::endl;
	else
		pref_outFile << "param gamma := 0.1;" << std::endl;			// valore negativo: aumenta consumo dei link
	pref_outFile << std::endl;

	// The model provides a simple way for forcing the allocation of a VNF into a specific PoP.
	// Every pair (PoP, Vnf) marked with a 1 (one) is constrained.
	pref_outFile << "param:		bound :=" << std::endl;
	if ((NS_json->has_member( "fixVnf01" )) && (NS_json->has_member( "toPoP01" ))) {
		std::string		fixedVNF = NS_json->get( "fixVnf01" ).as<std::string>();
		std::string		toPoP = NS_json->get( "toPoP01" ).as<std::string>();
		for (auto it = pop_id_array->begin_elements(); it != pop_id_array->end_elements(); ++it) {
			for (auto it2 = vnf_id_array->begin_elements(); it2 != vnf_id_array->end_elements(); ++it2) {
				if ((fixedVNF == ( it2->as<std::string>() )) && (toPoP == ( it->as<std::string>() )))
					pref_outFile << "\"" << it2->as<std::string>() << "\" \"" << it->as<std::string>() << "\" 1" << std::endl;
				else
					pref_outFile << "\"" << it2->as<std::string>() << "\" \"" << it->as<std::string>() << "\" 0" << std::endl;
			}
		}
	}
	else {
		for (auto it = pop_id_array->begin_elements(); it != pop_id_array->end_elements(); ++it) {
			for (auto it2 = vnf_id_array->begin_elements(); it2 != vnf_id_array->end_elements(); ++it2) {
				pref_outFile << "\"" << it2->as<std::string>() << "\" \"" << it->as<std::string>() << "\" 0" << std::endl;
			}
		}
	}

	for (auto it = pop_id_array->begin_elements(); it != pop_id_array->end_elements(); ++it) {
		for (auto it2 = ns_connection_points->begin_elements(); it2 != ns_connection_points->end_elements(); ++it2) {
			pref_outFile << "\"/" << it2->as<std::string>() << "\" \"" << it->as<std::string>() << "\" 0" << std::endl;
		}
	}



	pref_outFile << ";" << std::endl << std::endl;

	pref_outFile << "end;" << std::endl;

	pref_outFile.close();

	return 0;
}

int build_solution( glp_prob *problem, const jsoncons::json * const pop_link_detail_array, jsoncons::json * const solution ) {

	// I admit this is quite risky...
	// It scans the entire problem for searching whose lines begin with 'y' or 'x'; if any of these lines has a value of
	// 1 (one), it means that the solver allocates a vnf into a PoP (for the 'y') or a vnf link into a link between PoP ('x');
	// note that there might be several PoP links allocated for each VNF link.
	// Thanks to the funky naming of GLPK variables, each item in the .dat files that includes a slash (/) is surrounded
	// by single quotes ('), and since the algo separates each item by looking for quotes, it is MANDATORY that NS_id,
	// VNF_id, link_id and everything that appears on the .dat contains at least a slash.
	// This is very breakable and a different naming convention and search algo must be evaluated before the final release.
	// HA! Double quotes don't do their job.

	jsoncons::json		vnf_pop_array( jsoncons::json::an_array );
	jsoncons::json		links_array( jsoncons::json::an_array );
	jsoncons::json		temp_json_item;
	std::string			temp_str, first_item, second_item, third_item, last_item;
	size_t				item_begin, item_end;

	int col_number = glp_get_num_cols( problem );

	for ( int i = 0; i < col_number; ++i ) {
#ifdef DEBUGPRINT
		std::cout << glp_get_col_name( problem, i + 1 ) << " " << glp_mip_col_val( problem, i + 1 ) << std::endl;
#endif
		// Be careful! Mathprog indexes start from 1...
		if (glp_mip_col_val( problem, i + 1 ) == 1) {
			temp_str = glp_get_col_name( problem, i + 1 );

			// Evaluating PoP - VNF
			if (temp_str[0] == 'y') {
				item_begin = temp_str.find_first_of( "'", 0 );
				item_end   = temp_str.find_first_of( "'", item_begin + 1 );
				first_item = temp_str.substr( item_begin + 1, item_end - item_begin - 1 );
				item_begin = temp_str.find_first_of( "'", item_end + 1 );
				item_end   = temp_str.find_first_of( "'", item_begin + 1 );
				last_item  = temp_str.substr( item_begin + 1, item_end - item_begin - 1 );

				temp_json_item.clear();
				if (first_item.at(0) == '/')
					first_item = first_item.substr(1);
				temp_json_item["vnf"] = first_item;
				temp_json_item["maps_to_PoP"] = last_item;
				vnf_pop_array.add( temp_json_item );
			}

			// evaluating PoP link - VNF link
			if (temp_str[0] == 'x') {
				item_begin = temp_str.find_first_of( "'", 0 );
				item_end   = temp_str.find_first_of( "'", item_begin + 1 );
				first_item = temp_str.substr( item_begin + 1, item_end - item_begin - 1 );
				if (first_item.at(0) == '/')
					first_item = first_item.substr(1);
				item_begin = temp_str.find_first_of( "'", item_end + 1 );
				item_end   = temp_str.find_first_of( "'", item_begin + 1 );
				second_item = temp_str.substr( item_begin + 1, item_end - item_begin - 1 );
				if (second_item.at(0) == '/')
					second_item = second_item.substr(1);
				item_begin = temp_str.find_first_of( "'", item_end + 1 );
				item_end   = temp_str.find_first_of( "'", item_begin + 1 );
				third_item = temp_str.substr( item_begin + 1, item_end - item_begin - 1 );
				item_begin = temp_str.find_first_of( "'", item_end + 1 );
				item_end   = temp_str.find_first_of( "'", item_begin + 1 );
				last_item  = temp_str.substr( item_begin + 1, item_end - item_begin - 1 );

				temp_json_item.clear();
				temp_json_item["from"] = first_item;
				temp_json_item["to"] = second_item;
				for (auto it = pop_link_detail_array->begin_elements(); it != pop_link_detail_array->end_elements(); ++it) {
					if ((third_item == it->get( "source" ).as<std::string>()) && (last_item == it->get( "target" ).as<std::string>() )) {
						temp_json_item["maps_to_link"] = it->get( "identifier" ).as<std::string>();
						break;
					}
				}

				links_array.add( temp_json_item );
			}
		}
	}

	(*solution)["vnf_mapping"] = vnf_pop_array;
	(*solution)["links_mapping"] =links_array;

	return 0;
}

void add_timestamp( jsoncons::json * const solution ) {
	std::time_t creationTime = time( 0 );
#ifdef __unix__
	char		*creationTimeChar;
	creationTimeChar = ctime( &creationTime );
#endif
#ifdef _WIN32
	char		creationTimeChar[256];
	ctime_s( creationTimeChar, 256, &creationTime );
#endif
	std::string creationTimeStr = std::string( creationTimeChar );

	(*solution)["created_at"] = creationTimeStr.substr( 0, creationTimeStr.length() - 1 );

	return;
}

int build_error( const int step, const int status, jsoncons::json * const solution ) {

	switch (step) {
	case 0:
		(*solution)["Error"] = std::string( "Error in LP problem" );
		switch (status) {
		case GLP_INFEAS: (*solution)["Info"] = std::string( "Simplex solution is infeasible" );
			break;
		case GLP_NOFEAS: (*solution)["Info"] = std::string( "Simplex problem has no feasible solution" );
			break;
		case GLP_UNBND: (*solution)["Info"] = std::string( "Simplex problem has no bounded solution" );
			break;
		case GLP_UNDEF: (*solution)["Info"] = std::string( "Simplex solution is undefined" );
			break;
		}
		break;
	case 1:
		(*solution)["Error"] = std::string( "Error in MIP problem" );
		switch (status) {
		case GLP_NOFEAS: (*solution)["Info"] = std::string( "MIP problem has no feasible solution" );
			break;
		case GLP_UNDEF: (*solution)["Info"] = std::string( "MIP solution is undefined" );
			break;
		}
		break;
	case 2:
		(*solution)["Error"] = std::string( "Error in postsolve" );
		(*solution)["Info"] = std::string( "Postsolve errorcode: " + status );
		break;
	}
	return 0;
}

int main( int argc, char **argv ) {

	int				glpk_err_dat, glpk_err_gen, glpk_err_post, glpk_err_save; //glpk_err_mod;		// Error status
	int				glp_status, mip_status;
	std::string		NSinFilename;
	std::string		NIinFilename;
	std::string		modFilename		= BINPATH + std::string( "workspace/TNOVA.mod" );
	std::string		NIdatFilename	= BINPATH + std::string( "workspace/NI_generated.dat" );
	std::string		NSdatFilename	= BINPATH + std::string( "workspace/NS_generated.dat" );
	std::string		prefdatFilename = BINPATH + std::string( "workspace/pref_generated.dat" );
	std::string		outFilename		= BINPATH + std::string( "workspace/print_mip.out" );
	std::string		jsonOutFilename;
	std::ofstream	jsonOutFile;
	glp_prob		*mpl_problem;
	glp_tran		*mpl_translator;
	jsoncons::json	pop_link_detail_array( jsoncons::json::an_array );
	jsoncons::json	pop_id_array( jsoncons::json::an_array );
	jsoncons::json	vnf_id_array( jsoncons::json::an_array );
	jsoncons::json	ns_connection_points( jsoncons::json::an_array );
	jsoncons::json	solution_json;
	jsoncons::json  NS_json;

	glpk_err_dat = glpk_err_gen = glpk_err_post = glpk_err_save = 0; // glpk_err_mod = 0;

	if (argc > 1){
		NSinFilename = std::string( argv[1] );
		NIinFilename = std::string( argv[2] );
		jsonOutFilename = std::string( argv[3] );
	}
	else {
		NSinFilename = std::string( "workspace/NS.json" );
		NIinFilename = std::string( "workspace/NI.json" );
		jsonOutFilename = std::string( "workspace/mapper_response.json" );
		std::cout << "Invalid number of arguments! Using default filenames..." << std::endl;
	}

	// scan of json files and build each .dat
	build_NSdat( NSinFilename, &vnf_id_array, &NS_json, &ns_connection_points );
	build_NIdat( NIinFilename, &pop_link_detail_array, &pop_id_array, &vnf_id_array, &ns_connection_points );
	build_prefdat( &pop_id_array, &vnf_id_array, &NS_json, &ns_connection_points );

	// creates an empty glpk problem
	mpl_problem = glp_create_prob();
	// allocates the mpl translator
	mpl_translator = glp_mpl_alloc_wksp();
	// loads the mpl model into the mpl translator
	//glpk_err_mod =
	glp_mpl_read_model( mpl_translator, modFilename.c_str(), 1 );
	// loads the mpl datafiles into the mpl translator
	glpk_err_dat = glp_mpl_read_data( mpl_translator, NIdatFilename.c_str() );
	glpk_err_dat = glp_mpl_read_data( mpl_translator, NSdatFilename.c_str() );
	glpk_err_dat = glp_mpl_read_data( mpl_translator, prefdatFilename.c_str() );

	// generate a model its description loaded in the translator
	glpk_err_gen = glp_mpl_generate( mpl_translator, NULL );
	if (glpk_err_dat == 0)
		std::cout << "mpl generate: OK" << std::endl;
	else
		std::cout << "mpl generate fail! Error code: " + std::to_string( glpk_err_gen ) << std::endl;

	// builds a problem instance from the model
	glp_mpl_build_prob( mpl_translator, mpl_problem );

	// Solves the LP problem with simplex method...
	glp_simplex( mpl_problem, NULL );
	// ...and gets the solution status
	glp_status = glp_get_status( mpl_problem );
	switch (glp_status) {
	case GLP_OPT: std::cout << "Simplex solution is optimal" << std::endl;
		break;
	case GLP_FEAS: std::cout << "Simplex solution is feasible" << std::endl;
		break;
	case GLP_INFEAS: std::cout << "Simplex solution is infeasible" << std::endl;
		break;
	case GLP_NOFEAS: std::cout << "Simplex problem has no feasible solution" << std::endl;
		break;
	case GLP_UNBND: std::cout << "Simplex problem has no bounded solution" << std::endl;
		break;
	case GLP_UNDEF: std::cout << "Simplex solution is undefined" << std::endl;
		break;
	}
	if ((glp_status != GLP_OPT) && (glp_status != GLP_FEAS)) {
		build_error( 0, glp_status, &solution_json );
	}

	// solve MIP problem with the branch-and-cut method
	glp_intopt( mpl_problem, NULL );
	mip_status = glp_mip_status( mpl_problem );
	switch (mip_status) {
	case GLP_OPT: std::cout << "MIP solution is optimal" << std::endl;
		break;
	case GLP_FEAS: std::cout << "MIP solution is feasible" << std::endl;
		break;
	case GLP_NOFEAS: std::cout << "MIP problem has no feasible solution" << std::endl;
		break;
	case GLP_UNDEF: std::cout << "MIP solution is undefined" << std::endl;
		break;
	}
	if ((mip_status != GLP_OPT) && (mip_status != GLP_FEAS)) {
		build_error( 1, mip_status, &solution_json );
	}

	// copies the solution back to the translator workspace and executes all the remaining
	// model statements which follow the solve statement
	// GLP_MIP specifies mixed integer solution
	glpk_err_post = glp_mpl_postsolve( mpl_translator, mpl_problem, GLP_MIP );
	if (glpk_err_post == 0)
		std::cout << "mpl post-solve: OK" << std::endl;
	else {
		std::cout << "mpl post-solve fail! Error code: " + std::to_string( glpk_err_post ) << std::endl;
		build_error( 2, glpk_err_post, &solution_json );
	}

	// adding the timestamp to the solution
	add_timestamp( &solution_json );

	// if solver has not broken, builds a solution in json format
	if (!solution_json.has_member("Error"))
		build_solution( mpl_problem, &pop_link_detail_array, &solution_json );

	// saves the mip solution to file (not mandatory, just for debugging purpose)
	glpk_err_save = glp_print_mip( mpl_problem, outFilename.c_str() );
	// saves the json solution to file
	jsonOutFile.open( jsonOutFilename.c_str(), std::ios::out );
	jsonOutFile << jsoncons::pretty_print( solution_json ) << std::endl;
	jsonOutFile.close();

#ifdef DEBUGPRINT
	std::cout << jsoncons::pretty_print( solution_json ) << std::endl;
#endif
	std::cout << "Done." << std::endl;
	//std::cout << "(Press return)" << std::endl;
	//getchar();

}

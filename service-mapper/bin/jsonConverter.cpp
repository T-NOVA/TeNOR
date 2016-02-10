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
// g++ -I./include/ -O0 -g3 -Wall -c -fmessage-length=0 -std=c++11 -MMD -MP -o test01.obj jsonConverter.cpp
// g++ -o "jsonConverter" test01.obj

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
		fakelink_detail_attributes["occi.epa.pop.bw_Mbps"] = std::string( "100.0" );
		fakelink_detail_attributes["occi.epa.pop.bw_util_Mbps"] = std::string( "100.0" );
		fakelink_detail_attributes["occi.epa.pop.roundtrip_time_sec"] = std::string( "1.0" );
		fakelink_detail["attributes"] = fakelink_detail_attributes;
		pop_link_detail_array->add( fakelink_detail );
	}

	// Begin write NI_generated.dat
	// data;
	NI_outFile << "  /* NI generata da NI.json */" << std::endl;
	NI_outFile << std::endl;

    // Keeping track of the link_id, since the solver works with source/dest pairs
    // and this information get lost in the process...
    // This table is used only in creating the json response
    NI_outFile << "/*" << std::endl;
    NI_outFile << "Not used for the actual computation!" << std::endl;
    NI_outFile << "Link IDs | source PoP | target PoP" << std::endl;
    for (auto it = pop_link_detail_array->begin_elements(); it != pop_link_detail_array->end_elements(); ++it) {
        NI_outFile
          << it->get( "identifier" ).as<std::string>() << " "
          << it->get( "source" ).as<std::string>() << " "
          << it->get( "target" ).as<std::string>() << std::endl;
    }
    NI_outFile << "*/" << std::endl << std::endl;

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
	NI_outFile << "set NT := cpu ram hdd gpu dpdk aes;" << std::endl << std::endl;

	// set LT
	NI_outFile << "set LT := bw;" << std::endl << std::endl;

	// param: ResourceNodeCapacity
	// Note: we set negative resources values (due to overcommitting) to 0.
	NI_outFile << "param: 		ResourceNodeCapacity :=" << std::endl;
	for (auto it = pop_id_array->begin_elements(); it != pop_id_array->end_elements(); ++it) {
		temp_pop_id = it->as<std::string>();
		int temp_aggregate_cpu  = aggregate_resources_json[temp_pop_id]["aggregate_cpus"].as<int>();
		int temp_aggregate_ram  = aggregate_resources_json[temp_pop_id]["aggregate_ram"].as<int>();
		int temp_aggregate_hdd  = aggregate_resources_json[temp_pop_id]["aggregate_hdd"].as<int>();
		int temp_aggregate_gpu  = aggregate_resources_json[temp_pop_id]["gpu_count"].as<int>();
		int temp_aggregate_dpdk = aggregate_resources_json[temp_pop_id]["dpdk_nic_count"].as<int>();
		int temp_aggregate_aes  = aggregate_resources_json[temp_pop_id]["aggregate_cpu_accel_aes-ni"].as<int>();

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

		if (temp_aggregate_gpu >= 0)
			NI_outFile << "\"" << temp_pop_id << "\" gpu " << aggregate_resources_json[temp_pop_id]["gpu_count"].as<std::string>() << std::endl;
		else
			NI_outFile << "\"" << temp_pop_id << "\" gpu 0" << std::endl;

		if (temp_aggregate_dpdk >= 0)
			NI_outFile << "\"" << temp_pop_id << "\" dpdk " << aggregate_resources_json[temp_pop_id]["dpdk_nic_count"].as<std::string>() << std::endl;
		else
			NI_outFile << "\"" << temp_pop_id << "\" dpdk 0" << std::endl;

		if (temp_aggregate_aes >= 0)
			NI_outFile << "\"" << temp_pop_id << "\" aes " << aggregate_resources_json[temp_pop_id]["aggregate_cpu_accel_aes-ni"].as<std::string>() << std::endl;
		else
			NI_outFile << "\"" << temp_pop_id << "\" aes 0" << std::endl;
	}
	NI_outFile << ";" << std::endl << std::endl;

	// param: ResourceLinkCapacity
	NI_outFile << "param: 		ResourceLinkCapacity :=" << std::endl;
	for (auto it = pop_link_detail_array->begin_elements(); it != pop_link_detail_array->end_elements(); ++it) {
		source_node = it->get( "source" ).as<std::string>();
		destination_node = it->get( "target" ).as<std::string>();
		std::string bw = it->get( "attributes" ).get( "occi.epa.pop.bw_Mbps" ).as<std::string>();
		std::string bw_ut = it->get( "attributes" ).get( "occi.epa.pop.bw_util_Mbps" ).as<std::string>();
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
			NI_outFile << "\"/" << it2->as<std::string>() << "\" \"" << it->as<std::string>() << "\" 0" << std::endl;
		}
	}

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
	ns_virtual_links = NS_json->get( "virtual_links" );
	ns_nfp = NS_json->get( "network_forwarding_paths" );
	//*ns_connection_points = NS_json->get( "connection_points" );
	// This is wrong.
	*ns_connection_points = ns_nfp[0].get( "connection_points" );

	// Begin write NS_generated.dat
	NS_outFile << "  /* NS generated from " << filename << " */" << std::endl;
	NS_outFile << std::endl;

	// Keeping track of the virtual_link_id, since the solver works with source/dest pairs
    // and this information get lost in the process...
    // This table is used only in creating the json response
    NS_outFile << "/*" << std::endl;
    NS_outFile << "Not used for the actual computation!" << std::endl;
    NS_outFile << "Virtual link IDs | source VNF | target VNF" << std::endl;
    for (auto it = ns_virtual_links.begin_elements(); it != ns_virtual_links.end_elements(); ++it) {
		std::string source = it->get( "source" ).as<std::string>();
		std::string destin = it->get( "destination" ).as<std::string>();
		int temp_idx_src = source.find_first_of( ":", 0 );
		int temp_idx_dst = destin.find_first_of( ":", 0 );
		if ( temp_idx_src != -1 )
			source = source.substr( 0, temp_idx_src );
		if ( temp_idx_dst != -1 )
			destin = destin.substr( 0, temp_idx_dst );
        NS_outFile
          << it->get( "virtual_link_id" ).as<std::string>() << " "
          << source << " " << destin << std::endl;
    }
    NS_outFile << "*/" << std::endl << std::endl;

	NS_outFile << "/*" << std::endl;
    NS_outFile << "Used for filtering fake nodes introduced by the solver!" << std::endl;
	NS_outFile << "Actual VNFs" << std::endl;
	for (auto it = vnf_id_array->begin_elements(); it != vnf_id_array->end_elements(); ++it) {
		NS_outFile << it->as<std::string>() << std::endl;
	}
	NS_outFile << "*/" << std::endl << std::endl;


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
		NS_outFile << "\"" << temp_vnf_id << "\" gpu 0" << std::endl;
		NS_outFile << "\"" << temp_vnf_id << "\" dpdk " << it->get("req_data_accel_lib_dpdk").as<std::string>() << std::endl;
		NS_outFile << "\"" << temp_vnf_id << "\" aes " << it->get("req_cpu_accel_aes-ni").as<std::string>() << std::endl;
	}
	for (auto it = ns_connection_points->begin_elements(); it != ns_connection_points->end_elements(); ++it) {
		NS_outFile << "\"/" << it->as<std::string>() << "\" cpu 0" << std::endl;
		NS_outFile << "\"/" << it->as<std::string>() << "\" ram 0.0" << std::endl;
		NS_outFile << "\"/" << it->as<std::string>() << "\" hdd 0.0" << std::endl;
		NS_outFile << "\"/" << it->as<std::string>() << "\" gpu 0" << std::endl;
		NS_outFile << "\"/" << it->as<std::string>() << "\" dpdk 0" << std::endl;
		NS_outFile << "\"/" << it->as<std::string>() << "\" aes 0" << std::endl;
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

int main( int argc, char **argv ) {

	std::string		NSinFilename;
	std::string		NIinFilename;
	std::string		jsonOutFilename;
	std::ofstream	jsonOutFile;
	jsoncons::json	pop_link_detail_array( jsoncons::json::an_array );
	jsoncons::json	pop_id_array( jsoncons::json::an_array );
	jsoncons::json	vnf_id_array( jsoncons::json::an_array );
	jsoncons::json	ns_connection_points( jsoncons::json::an_array );
	jsoncons::json	solution_json;
	jsoncons::json  NS_json;

	if (argc > 1){
		NSinFilename = std::string( argv[1] );
		NIinFilename = std::string( argv[2] );
	}
	else {
		NSinFilename = std::string( "workspace/NS.json" );
		NIinFilename = std::string( "workspace/NI.json" );
		std::cout << "Invalid number of arguments! Using default filenames..." << std::endl;
	}

	// scan of json files and build each .dat
	build_NSdat( NSinFilename, &vnf_id_array, &NS_json, &ns_connection_points );
	build_NIdat( NIinFilename, &pop_link_detail_array, &pop_id_array, &vnf_id_array, &ns_connection_points );
	build_prefdat( &pop_id_array, &vnf_id_array, &NS_json, &ns_connection_points );

    // provvisorio: aggiungere altri controlli e return value
    return 0;
}

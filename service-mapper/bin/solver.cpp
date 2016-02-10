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

// g++ -I./include/ -O0 -g3 -Wall -c -fmessage-length=0 -std=c++11 -MMD -MP -o test02.obj solver.cpp
// g++ -o "solver" test02.obj -lglpk

#define DEBUGPRINT

#include "jsoncons/json.hpp"
#include <unordered_map>
#include <unordered_set>

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


int build_solution( glp_prob *problem, const jsoncons::json * const pop_link_detail_array, jsoncons::json * const solution ) {

	// Scan the entire problem for searching whose lines begin with 'y' or 'x'; if any of these lines has a value of
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
	std::string			temp_source_dest_array[2];
    std::string			NI_generatedFilename		= BINPATH + std::string( "workspace/NI_generated.dat" );
	std::string			NS_generatedFilename		= BINPATH + std::string( "workspace/NS_generated.dat" );
	std::ifstream		NI_generatedFile;
	std::ifstream		NS_generatedFile;
	size_t				item_begin, item_end;
	std::unordered_map <std::string, std::string[2]> link_ids_map = std::unordered_map <std::string, std::string[2]>();
	std::unordered_map <std::string, std::string[2]> vld_ids_map  = std::unordered_map <std::string, std::string[2]>();
	std::unordered_set <std::string> filtered_vnf_set = std::unordered_set <std::string>();

	// Build a temporary map of link_id => [source_pop, dest_pop] reading data from NI_generated.dat
	// Seek for the right line
	NI_generatedFile.open( NI_generatedFilename.c_str(), std::ios::in );
	while (getline( NI_generatedFile, temp_str )) {
		if (temp_str != "Link IDs | source PoP | target PoP")
			continue;
		else
			break;
	}
	// Do the actual list
	while (getline( NI_generatedFile, temp_str )) {
		if (temp_str == "*/")
			break;
		item_begin   = temp_str.find_first_of( " " );					// from beginning of the line to the first space
		item_end	 = temp_str.find_first_of( " ", item_begin + 1 );	// from first space to the second space
		temp_source_dest_array[0] = temp_str.substr( item_begin + 1, item_end - item_begin - 1 );
		temp_source_dest_array[1] = temp_str.substr( item_end + 1, std::string::npos );
		link_ids_map.emplace( temp_str.substr( 0, item_begin ), temp_source_dest_array );
	}

	// Do the same for the virtual link ids, reading data from NS_generated
	NS_generatedFile.open( NS_generatedFilename.c_str(), std::ios::in );
	while (getline( NS_generatedFile, temp_str )) {
		if (temp_str != "Virtual link IDs | source VNF | target VNF")
			continue;
		else
			break;
	}
	while (getline( NS_generatedFile, temp_str )) {
		if (temp_str == "*/")
			break;
		item_begin   = temp_str.find_first_of( " ", 0 );				// from beginning of the line to the first space
		item_end	 = temp_str.find_first_of( " ", item_begin + 1 );	// from first space to the second space
		temp_source_dest_array[0] = temp_str.substr( item_begin + 1, item_end - item_begin - 1 );
		temp_source_dest_array[1] = temp_str.substr( item_end + 1, std::string::npos );
		vld_ids_map.emplace( temp_str.substr( 0, item_begin ), temp_source_dest_array );
	}

	// Read the list of the actual VNFs composing the service
	while (getline( NS_generatedFile, temp_str )) {
		if (temp_str != "Actual VNFs")
			continue;
		else
			break;
	}
	while (getline( NS_generatedFile, temp_str )) {
		if (temp_str == "*/")
			break;
		if (temp_str.at(0) == '/')
			temp_str = temp_str.substr(1);
		filtered_vnf_set.emplace( temp_str );
	}

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
				// Adding only the actual VNFs, ignoring the dummy ones
				if (filtered_vnf_set.find( first_item ) != filtered_vnf_set.end()) {
					temp_json_item["vnf"] = first_item;
					temp_json_item["maps_to_PoP"] = last_item;
					vnf_pop_array.add( temp_json_item );
				}
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

				std::string link_id, vld_id;
				// third_item and last_item are the source and destination PoP of the NI link.
				// Find the link_id that is associated with that.
				for (auto it = link_ids_map.begin(); it != link_ids_map.end(); ++it) {
					if ((it->second[0] == third_item) && (it->second[1] == last_item)) {
						link_id = it->first;
						break;
					}
				}

				// Do the same with the first_item and second_item which are the source and
				// destination VNF.
				for (auto it = vld_ids_map.begin(); it != vld_ids_map.end(); ++it) {
					if ((it->second[0] == first_item) && (it->second[1] == second_item)) {
						vld_id = it->first;
						break;
					}
				}

				temp_json_item["vld_id"] = vld_id;
				temp_json_item["maps_to_link"] = link_id;
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
		(*solution)["error"] = std::string( "Error in LP problem" );
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
		(*solution)["error"] = std::string( "Error in MIP problem" );
		switch (status) {
		case GLP_NOFEAS: (*solution)["Info"] = std::string( "MIP problem has no feasible solution" );
			break;
		case GLP_UNDEF: (*solution)["Info"] = std::string( "MIP solution is undefined" );
			break;
		}
		break;
	case 2:
		(*solution)["error"] = std::string( "Error in postsolve" );
		(*solution)["info"] = std::string( "Postsolve errorcode: " + status );
		break;
	}
	return 0;
}

int main( int argc, char **argv ) {

	int				glpk_err_dat, glpk_err_gen, glpk_err_post, glpk_err_save; //glpk_err_mod;		// Error status
	int				glp_status, mip_status;
	std::string		modFilename		= BINPATH + std::string( "workspace/TNOVA.mod" );
	std::string		NIdatFilename	= BINPATH + std::string( "workspace/NI_generated.dat" );
	std::string		NSdatFilename	= BINPATH + std::string( "workspace/NS_generated.dat" );
	std::string		prefdatFilename = BINPATH + std::string( "workspace/pref_generated.dat" );
	std::string		outFilename		= BINPATH + std::string( "workspace/print_mip.out" );
	std::string		jsonOutFilename = BINPATH + std::string( "workspace/mapperResponse.json");
	std::ofstream	jsonOutFile;
	glp_prob		*mpl_problem;
	glp_tran		*mpl_translator;
	jsoncons::json	pop_link_detail_array( jsoncons::json::an_array );
	jsoncons::json	pop_id_array( jsoncons::json::an_array );
	jsoncons::json	vnf_id_array( jsoncons::json::an_array );
	jsoncons::json	ns_connection_points( jsoncons::json::an_array );
	jsoncons::json	solution_json;

	glpk_err_dat = glpk_err_gen = glpk_err_post = glpk_err_save = 0;
/*
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
*/
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
	if (!solution_json.has_member("error"))
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

}

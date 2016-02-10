# Copyright 2014-2016 Universita' degli studi di Milano
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# -----------------------------------------------------
#
# Authors:
#     Alessandro Petrini (alessandro.petrini@unimi.it)
#
# -----------------------------------------------------



# test with curl:
# curl -X POST localhost:4042/mapper -H 'Content-Type: application/json' -d '{"NS_id":"demo1", "NS_sla":"gold", "ir_simulation":"true"}'
# @see sm-unimi

require_relative 'sm-unimi_IR_helper'
require_relative 'sm-unimi_NS_helper'

class MapperUnimi < Sinatra::Application

	# Route: /mapper
	# Main service invoked by TeNOR. Request body must contain id of the NS to be instantiated.
	#
	# List of options in request payload:
	# NS_id				ID of the Netword Service to be instantiated
	# NS_sla			Flavour of the Network Service to be instantiated
	# tenor_api			web address of the TeNOR API (catalogs)
	# infr_repo_api		web address of the Infrastructure Repository
	# ir_simulation		if true, dummy IR data is used for testing purpose
	# ns_simulation		if true, dummy NS / VNF data is used for testing purpose
	# alpha				optional parameter to be passed to the solutor: weight of alpha parameter in objective function
	# beta				optional parameter to be passed to the solutor: weight of alpha parameter in objective function
	# gamma				optional parameter to be passed to the solutor: weight of alpha parameter in objective function
	# fixVnf01			forces the allocation of the first VNF of the NS to the PoP specified by the "toPoP01" parameter
	# toPoP01			states in which PoP should be allocated the VNF specified by the "fixVnf01" parameters
	#
	# Return statuses:
	# 0					Ok / mapping found
	# 1					No feasible solution found
	# -1				No matching NSd in NS catalog
	# -2				No matching SLA in NSd
	# -3				No matching VNFd in VNF catalog
	# -4				No matching flavour in vnf.deployment_flavour
	# -16				API call fail: /pop/
	# -17				API call fail: /pop/<pop_id>
	# -18				API call fail: /pop/link
	# -19				API call fail: /pop/link/<pop_link_id>
	# -20				API call fail: /pop/<pop-id>/hypervisor/
	# -21				API call fail: /pop/<pop_id>/hypervisor/<hypervisor_id>
	# -22				API call fail: /pop/<pop_id>/pcidev/?dpdk=true
	# -23				API call fail: /pop/<pop_id>/osdev/?category=compute
	# -32				API call fail: /network-services
	# -33				API call fail: /vnfs
	# -60				No matching NSd in dummy NS catalog
	# -61				No matching VNFd in dummy VNF catalog
	# -120				NS.json not found / not generated
	# -121				NI.json not found / not generated
	# -122				Invalid json request: no ns_id found
	#
	def mapper_manager()

		#ir_address       = 'http://143.233.227.120:8888'
		#catalogs_address = 'http://apis.t-nova.eu/orchestrator'

		# prints usefull stuff
		debugprint = true

		# Parse request body
		return_message = {}
		puts request.body.read
		request.body.rewind
		requestbody_hash = JSON.parse(request.body.read)

		ir_address       = requestbody_hash['infr_repo_api']
		catalogs_address = requestbody_hash['tenor_api']


		# Temporary keys in the request body: if true, IR/NS requests return the dummy NI/NSd/VNFd
		#if requestbody_hash.has_key?('ir_simulation')
		#	ir_simulation_requested = requestbody_hash['ir_simulation']
		#else
			ir_simulation_requested = "false"
		#end

		#if requestbody_hash.has_key?('ns_simulation')
		#	ns_simulation_requested = requestbody_hash['ns_simulation']
		#else
			ns_simulation_requested = "false"
		#end


		# Look for the NS_id into the request
		if requestbody_hash.has_key?('NS_id')
			ns_id = requestbody_hash['NS_id']
		elsif requestbody_hash.has_key?('ns_id')
			ns_id = requestbody_hash['ns_id']
	  	else
			status = {'status' => -122,
					'error' => "Invalid json request: no ns_id found"}
			return JSON.pretty_generate( status )
		end

		# Look for the NS_sla into the request
		ns_sla = ""
		if requestbody_hash.has_key?('NS_sla')
			ns_sla = requestbody_hash['NS_sla'].downcase
		end
		#bugfix for empty NS_sla
	  	if ns_sla == ""
			puts "\nWARNING: No NS_sla specified. 'gold' used by default.\n"
			ns_sla = "gold"
		end


		# Query to NS and VNF catalogs
		service_catalogs = NS_helper.new
		status = service_catalogs.queryServiceCatalogs( catalogs_address, requestbody_hash, ns_id, ns_sla, ns_simulation_requested, debugprint )
		if status['status'] < 0
			return JSON.pretty_generate( status )
		end

		# Query to Infrastructure Repository.
		ir = IR_helper.new
		status = ir.queryIR( ir_address, simulation=ir_simulation_requested, debugprint )
		if status['status'] < 0
			return JSON.pretty_generate( status )
		end



		# We collected all the data we needed, now let's call the GLPK solver but, before that,
		# check for the existance of generated datafiles before invoking the binary application
		if !File.exist?('bin/workspace/NS.json')
			puts "NS.json not found!"
			status = {'status' => -120,
					'error' => "NS.json not found / not generated"}
			return JSON.pretty_generate( status )
		end
		if !File.exist?('bin/workspace/NI.json')
			puts "NI.json not found!"
			status = {'status' => -121,
					'error' => "NI.json not found / not generated"}
			return JSON.pretty_generate( status )
		end



		# Let's make the actual call
		puts "System call to mapper"
		system("bin/jsonConverter bin/workspace/NS.json bin/workspace/NI.json")
		system("bin/solver")

		# Solver has returned a mapperResponse.json file containg the solution (or the error).
		# Add a second timestamp and return solution to Orchestrator
		mapper_solution_json = File.read('bin/workspace/mapperResponse.json')
		mapper_hash = JSON.parse(mapper_solution_json)
		time1 = Time.new
		mapper_hash['updated_at'] = time1.inspect

		if mapper_hash.has_key?("error")
			mapper_hash['status'] = 1
		else
			mapper_hash['status'] = 0
		end

		return JSON.pretty_generate(mapper_hash)
	end





	### UTILITIES
	# checks if an object is a number
	def is_number? string
		true if Float(string) rescue false
	end

	# Checks if a JSON message is valid
	#
	# @param [JSON] message some JSON message
	# @return [Hash, nil] if the parsed message is a valid JSON
	# @return [Hash, String] if the parsed message is an invalid JSON
	def parse_json(message)
		# Check JSON message format
		begin
			parsed_message = JSON.parse(message) # parse json message
		rescue JSON::ParserError => e
			# If JSON not valid, return with errors
			logger.error "JSON parsing: #{e.to_s}"
			return message, e.to_s + "\n"
		end

		return parsed_message, nil
	end

end

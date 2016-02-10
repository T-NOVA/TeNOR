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



# Helper class for querying the Network Service catalogue, Virtual Network Function catalog
# and building the data json file to be passed to the binary application

require_relative 'sm-unimi_converters'
#require_relative 'sm-unimi_dummyRest'

class NS_helper

	def queryServiceCatalogs(ns_address, requestbody_hash, ns_id, ns_sla, simulation, debugprint)

		conv = Sm_converters.new
		#dummyRest = Sm_dummyRest.new

		if simulation == "true"
			ns_base_address = "_"
		else
			ns_base_address = ns_address
		end

		# Query NS catalogue
		begin
			nsd_from_catalogue = RestClient.get(ns_base_address + '/network-services/' + ns_id, :accept => 'application/json')
		rescue => e
			if debugprint == true
				puts "\nmapper: API call fail /network-services\n"
				puts e
			end
			#nsd_from_catalogue = dummyRest.dummy_NScatalogue(ns_id, debugprint)
			return {'status' => -32,
					'error' => "API call fail: /network-services"}
		end

		# Check if the requested ns_id has its match in the nsd catalogue
		nsd_from_catalogue_hash = JSON.parse(nsd_from_catalogue)
		if nsd_from_catalogue_hash.has_key?('error')
			puts "\nmapper: No matching NSd in NS catalog\n"
			return {'status' => -1,
					'error' => "No matching NSd in NS catalog"}
		end


		# Select the requested flavour and extract its associated relevant VNFd data from the NSd
		constituent_vnf_array = Array.new
		nsd_from_catalogue_hash["sla"].each do |sla|
			if sla["id"].downcase == ns_sla
				sla["constituent_vnf"].each do |const_vnf|
					vnf_id_hash = Hash.new
					vnf_id_hash["vnf_id"] = "/" + const_vnf["vnf_reference"].to_s
					vnf_id_hash["vnf_flavour"] = const_vnf["vnf_flavour_id_reference"]
					vnf_id_hash["vnf_instances"] = const_vnf["number_of_instances"]
					constituent_vnf_array.push(vnf_id_hash)
				end
			end
		end
		if constituent_vnf_array == []
			puts "\nmapper: no matching SLA in NSd\n"
			return {'status' => -2,
					'error' => "No matching SLA in NSd"}
		end


		# Query the Virtual Network Function catalogue
		# We collected the NSd, now we check and collect the VNFd(s) the Network Service is composed by.
		vnf_id_array = Array.new
		vnf_requirements = Array.new
		vnfd_temp_hash = Hash.new
		constituent_vnf_array.each do |constituent_vnf|
			vnf_id = constituent_vnf["vnf_id"]
			vnf_id_array.push(vnf_id)
			vnf_flavour = constituent_vnf["vnf_flavour"]
			begin
				vnfd = RestClient.get(ns_base_address + '/vnfs/' + vnf_id, :accept => 'application/json')
			rescue => e
				if debugprint == true
					puts "mapper: API call fail /vnfs\n"
					puts e
				end
				#vnfd = dummyRest.dummy_VNFcatalogue(vnf_id, debugprint)
				return {'status' => -33,
						'error' => "API call fail: /vnfs"}
			end
			if vnfd == []
				puts "mapper: no matching VNFd in VNF catalog\n"
				return {'status' => -3,
						'error' => "No matching VNFd in VNF catalog"}
			end

			vnfd_temp_hash = JSON.parse( vnfd )

			# Now we scan the vnfd.deployment_flavour in the retrieved VNFd, looking for the matching requested flavour.
			# Init these vars with dummy values
			vdu_arr = Array.new
			#number_of_vdu_inst = "_"

			vnfd_temp_hash["vnfd"]["deployment_flavours"].each do |depl_flavour|
				#if vnf_flavour == depl_flavour["id"] ## In NSD it is referenced by id, while in vnf, id is ignored and it is referenced by flavour_key. This is messy.
				if vnf_flavour == depl_flavour["flavour_key"]
					vdu_arr = depl_flavour["vdu_reference"]
					#number_of_vdu_inst = depl_flavour["number_of_instances"]
				end
			end

			if (vdu_arr.empty?) #|| (number_of_vdu_inst == "_")
				puts "\nmapper: no matching flavour in vnf.deployment_flavour\n"
				return {'status' => -4,
						'error' => "No matching flavour in vnf.deployment_flavour"}
			end

			# Why whole lotta bandwidths?
			# tot_peak_bw is the aggregate of the "networking_resources"->"peak" values;
			# tot_aver_bw is the aggregate of the "networking_resources"->"average" values;
			# max_bw is the physical network interface card bandwidth specification (ex: 100Mbps)
			tot_vcpu = 0			# no unit of measurement
			tot_ram = 0.0			# converted and expressed in MBytes
			tot_hdd = 0.0			# converter and expressed in GBytes
			tot_peak_bw = 0			# converted and expressed in Mbps
			tot_aver_bw = 0			# converted and expressed in Mbps
			max_bw = 0.0
			curr_bw = 0.0			# converted and expressed in Mbps
			# ---
			tot_cpu_aesni = 0
			tot_dpdk = 0

			# We are collecting the aggregate of the requirements, even though it seems that in T-Nova
			# each VNF is composed by a single vdu...
			vnf_req = Hash.new
			vnfd_temp_hash["vnfd"]["vdu"].each do |vdu|
				vdu_arr.each do |vdu_name|
					if vdu["id"] == vdu_name
						tot_vcpu    += vdu["resource_requirements"]["vcpus"].to_i
						#tot_ram     += conv.ram_conversion(vdu["resource_requirements"]["memory"], vdu["resource_requirements"]["memory_unit"]) ### memory unit removed, apparently
						tot_ram     += conv.ram_conversion(vdu["resource_requirements"]["memory"], "GB")
						tot_hdd     += conv.hdd_conversion(vdu["resource_requirements"]["storage"]["size"], vdu["resource_requirements"]["storage"]["size_unit"])
						### networking resources still missing in the Marketplace generated VNFD
						if vdu["networking_resources"] == ""
							tot_peak_bw += 0
							tot_aver_bw += 0
						else
							tot_peak_bw += conv.bw_conversion(vdu["networking_resources"]["peak"])
							tot_aver_bw += conv.bw_conversion(vdu["networking_resources"]["average"])
						end
						if vdu["resource_requirements"]["network_interface_bandwidth"] == ""
							curr_bw	= 0
						else
							curr_bw = conv.bw_conversion(vdu["resource_requirements"]["network_interface_bandwidth"])
						end
						if curr_bw > max_bw
							max_bw = curr_bw
						end
						if vdu["resource_requirements"]["cpu_support_accelerator"].downcase.include? "aes-ni"
							tot_cpu_aesni += 1
						end
						if vdu["resource_requirements"]["data_processing_acceleration_library"].downcase.include? "dpdk"
							tot_dpdk += 1
						end
					end
				end
			end

			vnf_req = Hash.new
			vnf_req["vnf_id"]    = vnf_id
			vnf_req["vnf_flavour"] = vnf_flavour
			vnf_req["vnf_num_of_inst"] = constituent_vnf["vnf_instances"]
			vnf_req["req_vcpus"] = tot_vcpu #* number_of_vdu_inst.to_i
			vnf_req["req_ram"]   = tot_ram #* number_of_vdu_inst.to_i
			vnf_req["req_hdd"]   = tot_hdd #* number_of_vdu_inst.to_i
			vnf_req["req_nic_bw"]  = max_bw
			vnf_req["req_peak_bw"] = tot_peak_bw #* number_of_vdu_inst.to_i
			vnf_req["req_aver_bw"] = tot_aver_bw #* number_of_vdu_inst.to_i
			vnf_req["req_cpu_accel_aes-ni"] = tot_cpu_aesni #* number_of_vdu_inst.to_i
			vnf_req["req_data_accel_lib_dpdk"] = tot_dpdk #* number_of_vdu_inst.to_i

			vnf_requirements.push(vnf_req)
		end

		# Collecting data regarding interconnection graph between VNFs and between VNFs and outside world
		# As now, only point to point (E-line) links are supported (and, hopefully, it will always be)
		virtual_links_array = Array.new
		file = File.read( "json_templates/fake_vld_01.json" )		###
		fake_vld = JSON.parse(file)									### Temporary stuff
		nsd_from_catalogue_hash["vld"] = fake_vld					###
		nsd_from_catalogue_hash["vld"]["virtual_links"].each do |virtual_link|
			# Filter out non-data links and mismatching flavours
			if (virtual_link["alias"].downcase == "data") & (virtual_link["flavor_ref_id"] == ns_sla)
				virt_link_item = Hash.new
				virt_link_item["virtual_link_id"] = virtual_link["vld_id"]
				virt_link_item["root_requirements"] = conv.bw_conversion(virtual_link["root_requirements"])
				# Temporal bugfix since links may have unlimited bw requirements
				if virt_link_item["root_requirements"] == 0
					virt_link_item["root_requirements"] = 0.001
				end
				virt_link_item["source"] = virtual_link["connections"][0]
				virt_link_item["destination"] = virtual_link["connections"][1]
				virtual_links_array.push(virt_link_item)
			end
		end

		# --TODO-- considering the first nfp only
		network_forwarding_paths = Array.new
		file = File.read( "json_templates/fake_vnffgd_01.json" )	###
		fake_vnffgd = JSON.parse(file)								### Temporary stuff
		nsd_from_catalogue_hash["vnffgd"] = fake_vnffgd				###
		nsd_from_catalogue_hash["vnffgd"]["vnffgs"][0]["network_forwarding_path"].each do |nfp|
			nfp_item = Hash.new
			connection_points = Array.new
			nfp_item["nfp_id"] = nfp["nfp_id"]
			nfp_item["nfp_graph"] = nfp["graph"]
			nfp["connection_points"].each do |cp|
				connection_points.push(cp)
			end
			nfp_item["connection_points"] = connection_points
			network_forwarding_paths.push(nfp_item)
		end


		ns_out = Hash.new
		ns_out["ns_id"] = ns_id
		ns_out["ns_sla"] = ns_sla
		ns_out["vnf_id"] = vnf_id_array
		ns_out["vnf_req"] = vnf_requirements
		ns_out["virtual_links"] = virtual_links_array
		ns_out["network_forwarding_paths"] = network_forwarding_paths
		if ( requestbody_hash["alpha"] != "" ) & ( is_number?(requestbody_hash["alpha"]) )
			ns_out["alpha"] = requestbody_hash["alpha"]
		end
		if ( requestbody_hash["beta"] != "" ) & ( is_number?(requestbody_hash["beta"]) )
			ns_out["beta"] = requestbody_hash["beta"]
		end
		if ( requestbody_hash["gamma"] != "" ) & ( is_number?(requestbody_hash["gamma"]) )
			ns_out["gamma"] = requestbody_hash["gamma"]
		end
		if (requestbody_hash["fixVnf01"] != "") && (requestbody_hash["toPoP01"] != "")
			ns_out["fixVnf01"] = requestbody_hash["fixVnf01"]
			ns_out["toPoP01"] = requestbody_hash["toPoP01"]
		end

		nsreqFile = File.open('bin/workspace/NS.json', 'w') do |f|
			f.puts JSON.pretty_generate(ns_out)
		end

		return {'status' => 0,
				'error'=> "Ok"}

	end


	# checks if an object is a number
	def is_number? string
		true if Float(string) rescue false
	end


end

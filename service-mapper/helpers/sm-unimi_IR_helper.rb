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



# Helper class for querying the Infrastructure Repository and building
# the data json file to be passed to the binary application

require_relative 'sm-unimi_converters'
#require_relative 'sm-unimi_dummyRest'

class IR_helper

	# Queries the IR database for all the datas needed by the mapping algo; these are both aggregate
	# resources and DC features resources.
	# Data is then saved in bin/workspace/NI.json
	#
	# See http://wiki.t-nova.eu/tnovawiki/index.php/Final_Infrastructure_API_available and
	# http://wiki.t-nova.eu/tnovawiki/index.php/T3.2_Infrastructure_Repository
	# for a complete API reference
	#
	# API supports filtering, i.e.
	#   GET/<PoP_ID>/Resources?Type=VM&State=running
	# or
	#   GET/<PoP_ID>/Resources?Type=Service&State=Enable
	# but I haven't had the chance to try them in a working environment. Code may change drastically if
	# I decide to implement filtered-based queries!
	#
	def queryIR(ir_address, simulation, randNum, debugprint, overcommiting)

		conv = Sm_converters.new

		base_ir_address = ir_address

		# request list of PoP
		pop_id_array = Array.new
		temp_h = Hash.new
		begin
			pop_list = RestClient.get(base_ir_address + '/pop/', :accept => 'application/occi+json')
		rescue => e
			if debugprint == true
				puts 'API call fail /pop/\n'
				puts e
			end
			return {'status' => -16,
					'error' => "API call fail: /pop"}
		end
		temp_h = JSON.parse(pop_list)
		puts "Numbers of PoPs = " + temp_h.size.to_s + "\n"
		temp_h.each do |pop|
			pop_id_array.push(pop["identifier"])
		end


		# for each PoP, we build an hash containing all detailed infos
		temp_h.clear
		pop_detail_array = Array.new
		pop_id_array.each do |pop_id|
			begin
				pop_detail = RestClient.get(base_ir_address + '/pop/' + pop_id, :accept => 'application/occi+json')
			rescue => e
				if debugprint == true
					puts 'API call fail /pop/<pop_id>/\n'
				end
				return {'status' => -17,
						'error' => "API call fail: /pop/" + pop_id}
			end
			temp_h = JSON.parse(pop_detail)
			clear_unused_keys(temp_h)
			pop_detail_array.push(temp_h)
		end


		# Do the same with the links between PoPs
		pop_link_id_array = Array.new
		begin
			pop_link_list = RestClient.get(base_ir_address + '/pop/link/', :accept => 'application/occi+json')
		rescue => e
			if debugprint == true
				puts 'API call fail /pop/link/'
			end
			return {'status' => -18,
					'error' => "API call fail: /pop/link"}
		end
		temp_h = JSON.parse(pop_link_list)
		puts "Number of PoP links = " + temp_h.size.to_s + "\n"
		temp_h.each do |pop_link|
			pop_link_id_array.push(pop_link["identifier"])
		end


		# request detailed link descriptions
		temp_h.clear
		pop_link_detail_array = Array.new
		pop_link_id_array.each do |pop_link_id|
			begin
				pop_link_detail = RestClient.get(base_ir_address + '/pop/link/' + pop_link_id, :accept => 'application/occi+json')
			rescue => e
				if debugprint == true
					puts 'API call fail /pop/link/<pop_link_id>/'
				end
				return {'status' => -19,
						'error' => "API call fail: /pop/link/" + pop_link_id}
			end
				temp_h = JSON.parse(pop_link_detail)
				clear_unused_keys(temp_h)
				# Convert Gbps -> Mbps
				temp_h["attributes"]["occi.epa.pop.bw_Mbps"] = temp_h["attributes"]["occi.epa.pop.bw_Gps"].to_i * 1024;
				temp_h["attributes"]["occi.epa.pop.bw_util_Mbps"] = temp_h["attributes"]["occi.epa.pop.bw_util_Gps"].to_i * 1024;
				temp_h["attributes"].delete('occi.epa.pop.bw_Gps')
				temp_h["attributes"].delete('occi.epa.pop.bw_util_Gps')
				pop_link_detail_array.push(temp_h)
		end


		# Now we take care of the resources of each PoP. Note that, as now, we only farm for cpu, ram and hdd.
		# For each Pop, now we get the list of the hypervisors
		pop_hypervisors_hash = Hash.new
		hypervisors_list_hash = Hash.new
		number_of_hypervisors = 0
		pop_id_array.each do |pop_id|
			begin
				pop_hypervisors_list = RestClient.get(base_ir_address + pop_id + '/hypervisor/', :accept => 'application/occi+json')
			rescue => e
				if debugprint == true
					puts 'API call fail /pop/<pop-id>/hypervisor/'
				end
				return {'status' => -20,
						'error' => "API call fail: /pop/" + pop_id + "/hypervisor"}
			end
			temp_h = JSON.parse( pop_hypervisors_list )
			number_of_hypervisors += temp_h.size

			hypervisors_per_PoP_array = Array.new
			temp_h.each do |hypervisor_in_PoP|
				hypervisors_per_PoP_array.push( hypervisor_in_PoP["identifier"] )
			end
			hypervisors_list_hash[pop_id] = hypervisors_per_PoP_array
		end
		puts "Total number of hypervisors queried = " + number_of_hypervisors.to_s + "\n"
		# example hypervisors_list_hash:
		#{
		#	"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f4": [
		#		"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f4/hypervisor/hypervisor-1",
		#		"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f4/hypervisor/hypervisor-2"],
		#	"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f5": [
		#	    "/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f5/hypervisor/hypervisor-1",
		#	    "/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f5/hypervisor/hypervisor-2",
		#	    "/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f5/hypervisor/hypervisor-3"]
		#}

		# For each hypervisors, we collect the data for calculating the free aggregated resources.
		# Note that we just do this for ram, cpu and hdd
		# --TODO-- The total free resources are currently horribly wrong since they also consider the resources
		#          of the controller machines! I know that it must be filtered onto the compute nodes only!!!
		hypervisors_detail_hash = Hash.new
		pop_id_array.each do |pop_id|
			pop_aggregate_cpus = 0
			pop_aggregate_ram = 0
			pop_aggregate_hdd = 0
			pop_aggregate_cpu_aesni = 0
			pop_aggregate_data = Hash.new
			hypervisors_list_hash[pop_id].each do |hypervisor_id|

				begin
					hypervisor_detail = RestClient.get(base_ir_address + hypervisor_id, :accept => 'application/occi+json')
				rescue => e
					if debugprint == true
						puts 'API call fail /pop/<pop-id>/hypervisor/<hypervisor_id>'
						puts pop_id + hypervisor_id
					end
					return {'status' => -21,
							'error' => "API call fail: /pop/" + pop_id + "/hypervisor" + hypervisor_id}
				end

				hypervisor_detail_hash = JSON.parse( hypervisor_detail )
				if (hypervisor_detail_hash["attributes"]["occi.epa.attributes"]).is_a? String
					hypervisor_occi_epa_attributes_hash = JSON.parse( hypervisor_detail_hash["attributes"]["occi.epa.attributes"] )
				else
					hypervisor_occi_epa_attributes_hash = hypervisor_detail_hash["attributes"]["occi.epa.attributes"]
				end

				cpus       = hypervisor_occi_epa_attributes_hash["vcpus"]
				vcpus_used = hypervisor_occi_epa_attributes_hash["vcpus_used"]
				ram        = hypervisor_occi_epa_attributes_hash["memory_mb"]
				ram_used   = hypervisor_occi_epa_attributes_hash["memory_mb_used"]
				hdd        = hypervisor_occi_epa_attributes_hash["local_gb"]
				hdd_used   = hypervisor_occi_epa_attributes_hash["local_gb_used"]

				# Actual limits found on the OpenStack docs: 16 vcpus for each physical core and 1.5MB virtual ram
				# for each MB or ram. Disregard them and return only the difference between physical cores and vcpu used
				# (as suggested by Intel).
				# 14/Mar/16: enabling optional overcommitting
				if (overcommiting == "true")
					pop_aggregate_cpus += cpus * 16 - vcpus_used
					pop_aggregate_ram  += ram * 1.5 - ram_used
				else
					pop_aggregate_cpus += cpus - vcpus_used
					pop_aggregate_ram  += ram - ram_used
				end
				pop_aggregate_hdd  += hdd - hdd_used

				if hypervisor_occi_epa_attributes_hash["cpu_info"]["features"].include?("aes")
					pop_aggregate_cpu_aesni += 1
				end

			end
			pop_aggregate_data["aggregate_cpus"] = pop_aggregate_cpus
			pop_aggregate_data["aggregate_ram"]  = pop_aggregate_ram
			pop_aggregate_data["aggregate_hdd"]  = pop_aggregate_hdd
			pop_aggregate_data["aggregate_cpu_accel_aes-ni"]  = pop_aggregate_cpu_aesni
			hypervisors_detail_hash[pop_id] = pop_aggregate_data
		end

		puts "Done querying hypervisors"

		# Take care of the EPA features: collect the number of DPDK-enabled NICs and the number of GPUs in each PoP
		# and store in the PoP_aggregate_resources hash
		pop_id_array.each do |pop_id|
			begin
				dpdk_pcidev_list = RestClient.get(base_ir_address + pop_id + '/pcidev/?dpdk=true', :accept => 'application/occi+json')
			rescue => e
				if debugprint == true
					puts 'API call fail /pop/<pop_id>/pcidev/?dpdk=true'
				end
				return {'status' => -22,
						'error' => "API call fail: /pop/" + pop_id + "/pcidev/?dpdk=true"}
			end
			dpdk_pcidev = JSON.parse(dpdk_pcidev_list)
			hypervisors_detail_hash[pop_id]["dpdk_nic_count"] = dpdk_pcidev.length

			begin
				gpu_osdev_list = RestClient.get(base_ir_address + pop_id + '/osdev/?category=compute', :accept => 'application/occi+json')
			rescue => e
				if debugprint == true
					puts 'API call fail /pop/<pop_id>/osdev/?category=compute'
				end
				return {'status' => -23,
						'error' => "API call fail: /pop/" + pop_id + "/osdev/?category=compute"}
			end
			gpu_osdev = JSON.parse(gpu_osdev_list)
			hypervisors_detail_hash[pop_id]["gpu_count"] = gpu_osdev.length

			## Sometimes, GPU are not recognized by the OS, expecially when PCI-passthrough is enabled and
			## no drivers have been installed on the host OS.
			## Try the naive approach (get all the pcidev of each PoP, duh!)
			## Experimental - disabled for now
			#begin
			#	pcidev_list = RestClient.get(base_ir_address + pop_id + '/pcidev/', :accept => 'application/occi+json')
			#rescue => e
			#	if debugprint == true
			#		puts 'API call fail /pop/<pop_id>/pcidev/'
			#	end
			#	return {'status' => -22,
			#			'error' => "API call fail: /pop/" + pop_id + "/pcidev/"}
			#end
			#pcidev_hash = JSON.parse(pcidev_list)
			#gpu_counter = 0
			#pcidev_hash.each do |pcidev|
			#	begin
			#		pcidev_detail = RestClient.get(base_ir_address + pcidev["identifier"], :accept => 'application/occi+json')
			#	rescue => e
			#		if debugprint == true
			#			puts 'API call fail /pop/<pop_id>/pcidev/<pci_id>'
			#		end
			#		return {'status' => -22,
			#				'error' => "API call fail: /pop/" + pop_id + "/pcidev/<pci_id>"}
			#	end
			#	pcidev_detail_hash = JSON.parse(pcidev_detail)
			#	if pcidev_detail_hash["attributes"]["occi.epa.attributes"].include? "NVIDIA"
			#		gpu_counter = gpu_counter + 1
			#		puts "gpu found at " + pcidev_detail_hash["attributes"]["occi.epa.hostname"]
			#	end
			#end
			#hypervisors_detail_hash[pop_id]["gpu_count"] = gpu_counter
		end


		# build the final hash...
		outputHash = Hash.new
		outputHash.store( "PoP_id", pop_id_array )
		outputHash.store( "PoP_detail", pop_detail_array )
		outputHash.store( "PoP_link_id", pop_link_id_array )
		outputHash.store( "PoP_link_detail", pop_link_detail_array )
		outputHash.store( "PoP_aggregate_resources", hypervisors_detail_hash )

		# ...and save it to disk
		niFile = File.open('bin/workspace/NI' + randNum.to_s + '.json', 'w') do |f|
			f.puts JSON.pretty_generate( outputHash )
		end

		return {'status' => 0,
                'error'=> "Ok"}

	end


	# Aux function for removing all the useless key/value pairs from each response
	def clear_unused_keys(input_hash)
		if input_hash.has_key?('actions')
			input_hash.delete('actions')
		end
		if input_hash.has_key?('kind')
			input_hash.delete('kind')
		end
		if input_hash.has_key?('mixins')
			input_hash.delete('mixins')
		end
	end


end

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

class Sm_dummyRest

    ### Network Service and Virtual Network Function catalogs API query simulation
    def dummy_NScatalogue(ns_id, debugprint)
        if debugprint == true
            puts "\n"
            puts "NS request: " + ns_id
            puts "\n"
        end
        ns_id_hash = {
            "123" => 'json_templates/example_nsd.json',
            "2" => 'json_templates/NSD_example_v1.json',
            "demo1" => 'json_templates/NSD_demo1.json',
            "demo2" => 'json_templates/NSD_demo2.json',
            "demo3" => 'json_templates/NSD_demo3.json',
            "demo4" => 'json_templates/NSD_demo4.json' }
        if ns_id_hash.has_key?(ns_id)
            file = File.read( ns_id_hash[ns_id] )
        else
            return "Error -60"
        end

        hashed_json = JSON.parse(file)
        return JSON.pretty_generate(hashed_json)
    end


    def dummy_VNFcatalogue(vnf_id, debugprint)
        if debugprint == true
            puts "\n"
            puts "VNF request: " + vnf_id
            puts "\n"
        end
        vnf_id_hash = {
            "cd8c1b44-9230-49c8-9cb0-01e02b9df7ee" => 'json_templates/vTC_example_vnfd.json',
            "3a2971d0-2eae-11e5-a2cb-0800200c9a66" => 'json_templates/vTC_example_vnfd.json',
            "/vnf_demo1_0" => 'json_templates/vnf_demo1_0.json',
            "/vnf_demo1_1" => 'json_templates/vnf_demo1_1.json',
            "/vnf_demo1_2" => 'json_templates/vnf_demo1_2.json',
            "/vnf_demo2_0" => 'json_templates/vnf_demo2_0.json',
            "/vnf_demo2_1" => 'json_templates/vnf_demo2_1.json',
            "/vnf_demo2_2" => 'json_templates/vnf_demo2_2.json',
            "/vnf_demo3_0" => 'json_templates/vnf_demo3_0.json',
            "/vnf_demo3_1" => 'json_templates/vnf_demo3_1.json',
            "/vnf_demo3_2" => 'json_templates/vnf_demo3_2.json',
            "/vnf_demo4_0" => 'json_templates/vnf_demo4_0.json',
            "/vnf_demo4_1" => 'json_templates/vnf_demo4_1.json' }
        if vnf_id_hash.has_key?(vnf_id)
            file = File.read( vnf_id_hash[vnf_id] )
        else
            return "Error -61"
        end

        hashed_json = JSON.parse(file)
        return JSON.pretty_generate(hashed_json)
    end



    # Infrastructure repository API query simulation
	def dummy_pop_query()
		file = File.read('json_templates/fake_pop_list.json')
		hashed_json = JSON.parse(file)
		return JSON.pretty_generate(hashed_json)
	end

	def dummy_pop_link_query()
		file = File.read('json_templates/fake_pop_link_list.json')
		hashed_json = JSON.parse(file)
		return JSON.pretty_generate(hashed_json)
	end

	def dummy_pop_detail_query(pop_id)
		pop_detail_hash = {
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f4" => 'json_templates/fake_pop_01.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f5" => 'json_templates/fake_pop_02.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f6" => 'json_templates/fake_pop_03.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f7" => 'json_templates/fake_pop_04.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f8" => 'json_templates/fake_pop_05.json' }
		if pop_detail_hash[pop_id] != []
			file = File.read( pop_detail_hash[pop_id] )
		else
			return '{"error": "PoP detail query failure"}'
		end
		hashed_json = JSON.parse(file)
		return JSON.pretty_generate(hashed_json)
	end

	def dummy_pop_link_detail_query(pop_link_id)
		pop_link_detail_hash = {
			"/pop/link/85b0bc27-dff0-4399-8435-4fb2ed65790a" => 'json_templates/fake_pop_link_01.json',
			"/pop/link/85b0bc28-dff0-4399-8435-4fb2ed65790a" => 'json_templates/fake_pop_link_02.json',
			"/pop/link/85b0bc29-dff0-4399-8435-4fb2ed65790a" => 'json_templates/fake_pop_link_03.json',
			"/pop/link/85b0bc30-dff0-4399-8435-4fb2ed65790a" => 'json_templates/fake_pop_link_04.json',
			"/pop/link/85b0bc31-dff0-4399-8435-4fb2ed65790a" => 'json_templates/fake_pop_link_05.json',
			"/pop/link/85b0bc32-dff0-4399-8435-4fb2ed65790a" => 'json_templates/fake_pop_link_06.json',
			"/pop/link/85b0bc33-dff0-4399-8435-4fb2ed65790a" => 'json_templates/fake_pop_link_07.json',
			"/pop/link/85b0bc34-dff0-4399-8435-4fb2ed65790a" => 'json_templates/fake_pop_link_08.json',
			"/pop/link/85b0bc35-dff0-4399-8435-4fb2ed65790a" => 'json_templates/fake_pop_link_09.json',
			"/pop/link/85b0bc36-dff0-4399-8435-4fb2ed65790a" => 'json_templates/fake_pop_link_10.json' }
		if pop_link_detail_hash[pop_link_id] != []
			file = File.read( pop_link_detail_hash[pop_link_id] )
		else
			return '{"error": "PoP link detail query failure"}'
		end

		hashed_json = JSON.parse(file)
		return JSON.pretty_generate(hashed_json)
	end

	def dummy_pop_hypervisor_query(pop_id)
		hypervisor_id_hash = {
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f4/hypervisor/" => 'json_templates/fake_hyp_01.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f5/hypervisor/" => 'json_templates/fake_hyp_02.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f6/hypervisor/" => 'json_templates/fake_hyp_03.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f7/hypervisor/" => 'json_templates/fake_hyp_04.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f8/hypervisor/" => 'json_templates/fake_hyp_05.json' }
		if hypervisor_id_hash[pop_id] != []
			file = File.read( hypervisor_id_hash[pop_id] )
		else
			return '{"error": "PoP hypervisor list query failure"}'
		end

		hashed_json = JSON.parse(file)
		return JSON.pretty_generate(hashed_json)
	end

	def dummy_hypervisor_detail_query(hypervisor_id)
		hypervisor_detail_hash = {
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f4/hypervisor/hypervisor-1" => 'json_templates/fake_hypervisor_01.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f4/hypervisor/hypervisor-2" => 'json_templates/fake_hypervisor_02.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f4/hypervisor/hypervisor-3" => 'json_templates/fake_hypervisor_03.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f5/hypervisor/hypervisor-1" => 'json_templates/fake_hypervisor_04.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f5/hypervisor/hypervisor-2" => 'json_templates/fake_hypervisor_05.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f5/hypervisor/hypervisor-3" => 'json_templates/fake_hypervisor_06.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f6/hypervisor/hypervisor-1" => 'json_templates/fake_hypervisor_07.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f6/hypervisor/hypervisor-2" => 'json_templates/fake_hypervisor_08.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f6/hypervisor/hypervisor-3" => 'json_templates/fake_hypervisor_09.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f7/hypervisor/hypervisor-1" => 'json_templates/fake_hypervisor_10.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f7/hypervisor/hypervisor-2" => 'json_templates/fake_hypervisor_11.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f7/hypervisor/hypervisor-3" => 'json_templates/fake_hypervisor_12.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f8/hypervisor/hypervisor-1" => 'json_templates/fake_hypervisor_13.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f8/hypervisor/hypervisor-2" => 'json_templates/fake_hypervisor_14.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f8/hypervisor/hypervisor-3" => 'json_templates/fake_hypervisor_15.json' }
		if hypervisor_detail_hash[hypervisor_id] != []
			file = File.read( hypervisor_detail_hash[hypervisor_id] )
		else
			return '{"error": "PoP hypervisor query failure"}'
		end
		hashed_json = JSON.parse(file)
		return JSON.pretty_generate(hashed_json)
	end

	def dummy_dpdk_pcidev_query(pop_id)
		pop_detail_hash = {
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f4" => 'json_templates/fake_pcidev_pop_01.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f5" => 'json_templates/fake_pcidev_pop_02.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f6" => 'json_templates/fake_pcidev_pop_03.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f7" => 'json_templates/fake_pcidev_pop_04.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f8" => 'json_templates/fake_pcidev_pop_05.json' }
		if pop_detail_hash[pop_id] != []
			file = File.read( pop_detail_hash[pop_id] )
		else
			return '{"error": "PoP detail query failure"}'
		end
		hashed_json = JSON.parse(file)
		return JSON.pretty_generate(hashed_json)
	end

	def dummy_gpu_osdev_query(pop_id)
		pop_detail_hash = {
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f4" => 'json_templates/fake_osdev_pop_01.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f5" => 'json_templates/fake_osdev_pop_02.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f6" => 'json_templates/fake_osdev_pop_03.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f7" => 'json_templates/fake_osdev_pop_04.json',
			"/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f8" => 'json_templates/fake_osdev_pop_05.json' }
		if pop_detail_hash[pop_id] != []
			file = File.read( pop_detail_hash[pop_id] )
		else
			return '{"error": "PoP detail query failure"}'
		end
		hashed_json = JSON.parse(file)
		return JSON.pretty_generate(hashed_json)
	end

end

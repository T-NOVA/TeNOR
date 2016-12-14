require_relative 'spec_helper'

RSpec.describe HotGenerator do
  def app
    HotGenerator
  end

  describe 'POST /networkhot/:flavour' do
    context 'given an invalid content type' do
      let(:response) { post '/networkhot/flavor0', {nsd: {}, public_net_id: 'network_id', dns_server: "10.10.1.1"}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

      it 'responds with a 415' do
        expect(response.status).to eq 415
      end

      it 'responds with an empty body' do
        expect(response.body).to be_empty
      end
    end

    context 'given a valid NS' do
      nsd ='{
					"nsd":
					{"id":"56df37d5e4b01f97669827ad","name":"PXaaS 333","vendor":"3", "vld":{"number_of_endpoints":0,"virtual_links":[{"vld_id":"vld0","alias":"management","root_requirements":"Unlimeted","leaf_requirement":"Unlimeted","qos":{"average":"","peak":"","burst":""},"connections":["VNF#1002:ext_management"],"connectivity_type":"E-LAN","external_access":false,"merge":true,"sla_ref_id":"sla0"},{"vld_id":"vld1","alias":"ingress","root_requirements":"Unlimeted","leaf_requirement":"Unlimeted","qos":{"average":"","peak":"","burst":""},"connections":["VNF#1002:ext_data_in"],"connectivity_type":"E-LINE","external_access":true,"merge":false,"sla_ref_id":"sla0"},{"vld_id":"vld2","alias":"engress","root_requirements":"Unlimeted","leaf_requirement":"Unlimeted","qos":{"average":"","peak":"","burst":""},"connections":["VNF#1002:ext_data_out"],"connectivity_type":"E-LINE","external_access":true,"merge":false,"sla_ref_id":"sla0"}]}},
					"public_net_id": "network_id", "dns_server": "10.10.1.1", "nsr_id": "nsr_id"
			}'

      let(:response) { post '/networkhot/flavor0', nsd, rack_env={'CONTENT_TYPE' => 'application/json'} }

      it 'responds with a 200' do
        expect(response.status).to eq 200
      end

      it 'response body should contain a Hash (NS)' do
        expect(JSON.parse response.body).to be_a Hash
      end

      it 'response body should be equal' do
        valid_response = '{"heat_template_version":"2014-10-16","description":"PXaaS 333","parameters":{},"resources":{"56df37d5e4b01f97669827ad_0":{"type":"OS::Neutron::Router","properties":{"external_gateway_info":{"network":"network_id"},"name":"Tenor_nsr_id"}}},"outputs":{}}'
        expect(JSON.parse response.body).to eq(JSON.parse valid_response)
      end
    end
  end
end

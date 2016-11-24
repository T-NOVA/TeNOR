require_relative 'spec_helper'

RSpec.describe "Tenor" do

	before(:context) do
		@vnfds = []
		@nsds = []
		@pops = []
		@instances = []
		@pops_names = ["admin_v2", "admin_v3", "non_admin_v2", "non_admin_v3"]
		@arr_vnfds = [
	    #'vnfd-validator/assets/samples/vnfd_example.json',
	    #'vnfd-validator/assets/samples/vnfd_example.json',
	    'vnfd-validator/assets/samples/vnfd_example.json'
	  ]
		@arr_nsds = [
	    #'nsd-validator/assets/samples/nsd_example.json',
	    #'nsd-validator/assets/samples/vnfd_example.json',
	    'nsd-validator/assets/samples/nsd_example.json'
	  ]
	end

	after(:context) do
	end

	describe 'create PoPs' do
		context '' do

			before do
				@pops_names.each do |pop_name|
					begin
				    response = RestClient.get "#{$TENOR_URL}/pops/dc/name/#{pop_name}"
						pop = JSON.parse(response)
						response = RestClient.delete "#{$TENOR_URL}/pops/dc/#{pop['id']}"
				  rescue => e
				  end
			  end
			end

			it 'create pops' do
				host = @OPENSTACK_HOST
				dns = @OPENSTACK_DNS
				pop = {
			      name: "admin_v2",
			      host: host,
			      user: @OPENSTACK_USER,
			      password: @OPENSTACK_PASS,
			      tenant_name: @OPENSTACK_TENANT_NAME,
			      is_admin: true,
			      description: "",
			      extra_info: "keystone-endpoint=http://#{host}:35357/v2.0 orch-endpoint=http://#{host}:8004/v1 compute-endpoint=http://#{host}:8774/v2.1 neutron-endpoint=http://#{host}:9696/v2.0 dns=#{dns}"
			  }
				response = RestClient.post $TENOR_URL.to_s + '/pops/dc', pop.to_json, :content_type => :json
				expect(response.code).to eq 201
				pop = JSON.parse response.body
				@pops << pop['id']
				expect(JSON.parse response.body).to be_an Hash
			end
		end
	end

	describe 'Create descriptors ' do
		context 'given a valid descriptors' do

			before(:context) do
				@arr_nsds.each do |nsd|
					nsd = JSON.parse File.read(nsd)
					begin
						response = RestClient.get $TENOR_URL.to_s + '/network-services/'+ nsd['nsd']['id'].to_s
					rescue RestClient::ExceptionWithResponse => e
						puts e
					end
					if !response.nil?
						RestClient.delete $TENOR_URL.to_s + '/network-services/'+ nsd['nsd']['id'].to_s
					end
				end

				@arr_vnfds.each do |vnfd|
					vnfd = JSON.parse File.read(vnfd)
					begin
						response = RestClient.get $TENOR_URL.to_s + '/vnfs/'+ vnfd['vnfd']['id'].to_s
					rescue RestClient::ExceptionWithResponse => e
						puts e
					end
					if !response.nil?
						RestClient.delete $TENOR_URL.to_s + '/vnfs/'+ vnfd['vnfd']['id'].to_s
					end
				end
			end

			it 'create vnfds' do
				@arr_vnfds.each do |vnfd|
					vnfd = File.read(vnfd)
					response = RestClient.post $TENOR_URL.to_s + '/vnfs', vnfd, :content_type => :json
					expect(response.code).to eq 201
					vnfd = JSON.parse response.body
					@vnfds << vnfd['vnfd']['id']
					expect(JSON.parse response.body).to be_an Hash
				end
			end

			it 'create nsds' do
				@arr_nsds.each do |nsd|
					nsd = File.read(nsd)
					response = RestClient.post $TENOR_URL.to_s + '/network-services', nsd, :content_type => :json
					expect(response.code).to eq 201
					nsd = JSON.parse response.body
					@nsds << nsd['nsd']['id']
					expect(JSON.parse response.body).to be_an Hash
				end
			end
		end
	end

	describe 'Instantiate Network services instances' do
		context 'given a valid ids' do
			it '' do
				@pops.each do |pop_id|
					@nsds.each do |nsd_id|
						instance = {"ns_id": nsd_id, "callbackUrl":"https://httpbin.org/post", "pop_id": pop_id, "flavour":"basic"}
						response = RestClient.post "#{$TENOR_URL.to_s}/ns-instances", instance.to_json, :content_type => :json
						instance = JSON.parse response.body
						@instances << {:id => instance['id'], :status => "INIT"}
					end
				end
			end
		end
	end

	describe 'Get Network services instances status' do
		context '' do
			it 'iterating over the created instances' do
				#sleep(30)
				final_status = "INIT"
				counter = 0
				if !@instances.empty?
					while counter < 30 && final_status != 'INSTANTIATED' && final_status != 'START' do
						@instances.each do |instance|
							response = RestClient.get "#{$TENOR_URL.to_s}/ns-instances/#{instance[:id]}/status"
							status = response.body
							puts status
							instance[:status] = status
							if status == 'INSTANTIATED' || status == 'START'
								puts status
								puts @instances.find {|i| i[:status] != "INSTANTIATED"}
								puts @instances.find {|i| i[:status] != "START"}
				        if @instances.find {|i| i[:status] != "INSTANTIATED"} && @instances.find {|i| i[:status] != "START"}
				          next
				        else
				          counter = 30
				          break
				        end
				      elsif status == 'ERROR_CREATING'
				      end
						end
						sleep(20)
				    counter +=1
					end
				end
			end
		end
	end

	describe 'DELETE instances' do
		it "removing created instances" do
			@instances.each do |instance|
				response = RestClient.delete $TENOR_URL.to_s + '/ns-instances/' + instance[:id].to_s
				expect(response.code).to eq 200
			end
		end
	end

	describe 'DELETE PoPs ' do
		it "removing created pops" do
			@pops.each do |pop|
				response = RestClient.delete $TENOR_URL.to_s + '/pops/dc/' + pop.to_s
				expect(response.code).to eq 200
			end
		end
	end

	describe 'DELETE Descriptors ' do
		it "removing created descriptors" do
			@nsds.each do |nsd|
				response = RestClient.delete $TENOR_URL.to_s + '/network-services/' + nsd.to_s
				expect(response.code).to eq 200
			end
		end
		it "writes the message one letter at a time" do
			@vnfds.each do |vnfd|
				response = RestClient.delete $TENOR_URL.to_s + '/vnfs/' + vnfd.to_s
				expect(response.code).to eq 200
			end
		end
	end
end

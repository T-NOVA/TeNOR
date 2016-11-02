require 'rest-client'
require 'json'

@tenor = ARGV[0]
if ARGV[0].nil?
	@tenor = "localhost:4000"
end

@OPENSTACK_HOST = ENV['OPENSTACK_HOST']
@OPENSTACK_USER = ENV['OPENSTACK_USER']
@OPENSTACK_PASS = ENV['OPENSTACK_PASS']
@OPENSTACK_TENANT_NAME = ENV['OPENSTACK_TENANT_NAME']
@OPENSTACK_DNS = ENV['OPENSTACK_DNS']

if @OPENSTACK_HOST.nil?
  puts "Execute the environment script! (. ./end_to_end_env.sh)"
  exit
end

#host = "IP...."
#user = "admin"
#password = "pass"
#tenant_name = "admin"
#dns = "8.8.8.8"

@e2e = {
	:vnfd_id => nil,
	:nsd_id => nil,
	:pops => [],
  :instances => []
}

def end_to_end_script()

	host = @OPENSTACK_HOST
	user = @OPENSTACK_USER
	password = @OPENSTACK_PASS
	tenant_name = @OPENSTACK_TENANT_NAME
	dns = @OPENSTACK_DNS

  puts "Removing PoPs if exists...."
  pops_names = ["admin_v2", "admin_v3", "non_admin_v2", "non_admin_v3"]
  pops_names.each do |pop|
    remove_pops_if_exists(pop)
  end

  puts "All PoPs are removed\n"

	puts "Create a PoP with Admin role v2"
	obj = {
      name: "admin_v2",
      host: host,
      user: user,
      password: password,
      tenant_name: tenant_name,
      is_admin: true,
      description: "",
      extra_info: "keystone-endpoint=http://#{host}:35357/v2.0 orch-endpoint=http://#{host}:8004/v1 compute-endpoint=http://#{host}:8774/v2.1 neutron-endpoint=http://#{host}:9696/v2.0 dns=#{dns}"
  }
	pop_id, errors = create_pop(obj)
	recover_state(errors) if errors
	@e2e[:pops] << {:name => obj[:name], :id => pop_id}

	puts "Create a PoP with Admin role v3"
	obj = {
      name: "admin_v3",
      host: host,
      user: user,
      password: password,
      tenant_name: tenant_name,
      is_admin: true,
      description: "",
      extra_info: "keystone-endpoint=http://#{host}:35357/v3 orch-endpoint=http://#{host}:8004/v1 compute-endpoint=http://#{host}:8774/v2.1 neutron-endpoint=http://#{host}:9696/v2.0 dns=#{dns}"
  }
	pop_id, errors = create_pop(obj)
	recover_state(errors) if errors
	#@e2e[:pops] << {:name => obj[:name], :id => pop_id}

	puts "Create a PoP without Admin role v2"
	obj = {
      name: "non_admin_v2",
      host: host,
      user: user,
      password: password,
      tenant_name: tenant_name,
      is_admin: false,
      description: "",
      extra_info: "keystone-endpoint=http://#{host}:35357/v2.0 orch-endpoint=http://#{host}:8004/v1 compute-endpoint=http://#{host}:8774/v2.1 neutron-endpoint=http://#{host}:9696/v2.0 dns=#{dns}"
  }
	pop_id, errors = create_pop(obj)
	recover_state(errors) if errors
	@e2e[:pops] << {:name => obj[:name], :id => pop_id}

	puts "Create a PoP without Admin role v3"
	obj = {
      name: "non_admin_v3",
      host: host,
      user: user,
      password: password,
      tenant_name: tenant_name,
      is_admin: false,
      description: "",
      extra_info: "keystone-endpoint=http://#{host}:35357/v3 orch-endpoint=http://#{host}:8004/v1 compute-endpoint=http://#{host}:8774/v2.1 neutron-endpoint=http://#{host}:9696/v2.0 dns=#{dns}"
  }
	pop_id, errors = create_pop(obj)
	recover_state(errors) if errors
	#@e2e[:pops] << {:name => obj[:name], :id => pop_id}

	#create basic descriptors
  #check_if_descriptors()
	descriptors, errors = create_descriptors()
	recover_state(errors) if errors

	@e2e[:vnfd_id] = "2910"
	@e2e[:nsd_id] = "578e2db5e4b0356a4eb0d2b1"

	puts "Instantiate services .............................................."
	#instantiate to each PoP created
	@e2e[:pops].each do |pop|
		ns_instance_id, errors = create_instance(pop[:id])
    puts errors if errors
    recover_state(errors) if errors
    @e2e[:instances] << {:id => ns_instance_id, :status => "INIT"}
	end
	pop = @e2e[:pops].find { |p| p[:name] == "admin_v2"}
  #ns_instance, errors = create_instance(pop[:id])

  pop = @e2e[:pops].find { |p| p[:name] == "admin_v3"}
  #ns_instance = create_instance(pop[:id])

  pop = @e2e[:pops].find { |p| p[:name] == "non_admin_v2"}
  #ns_instance = create_instance(pop[:id])

  pop = @e2e[:pops].find { |p| p[:name] == "non_admin_v3"}
  #ns_instance = create_instance(pop[:id])

	#wait until instance is created
  puts "Waiting 30secs..."
  sleep(30)
  counter = 0
  final_status = 'INIT'

  while counter < 30 && final_status != 'INSTANTIATED' do
    @e2e[:instances].each do |instance|
      status, error = get_instance_status(instance[:id])
      instance[:status] = status
      puts "Counter: #{counter}. Instance: #{instance[:id].to_s}. Status: #{instance[:status].to_s}"
      recover_state("Error creating...") if error
      if status == 'INSTANTIATED'
        if @e2e[:instances].find {|ins| ins[:status] != "INSTANTIATED"}
          next
        else
          puts "All instantiated???"
          counter = 30
          break
        end
      elsif status == 'ERROR_CREATING'
        recover_state("Error creating...")
      end
    end
    sleep(20)
    counter +=1
  end

  puts "All instances created correctly..."

  puts "Removing..."

  @e2e[:instances].each do |instances|
		delete_instance(instances[:id])
	end
  puts "Waiting 60 secs before remove PoPs..."
  sleep(60)

	@e2e[:pops].each do |pop|
#		delete_pop(pop[:id])
	end
  delete_descriptors()
end

def delete_instance(id)
  begin
		response = RestClient.delete "#{@tenor}/ns-instances/#{id}", :content_type => :json
	rescue => e
		puts e
		return 400, e
	end
  response
end

def get_instance_status(id)
  begin
		response = RestClient.get "#{@tenor}/ns-instances/#{id}/status", :content_type => :json
	rescue => e
		puts e
		return 400, e
	end
  response
end

def create_instance(pop_id)
	instance = {"ns_id": @e2e[:nsd_id],"callbackUrl":"https://httpbin.org/post","pop_id": pop_id,"flavour":"basic"}
	begin
		response = JSON.parse(RestClient.post "#{@tenor}/ns-instances", instance.to_json, :content_type => :json)
	rescue => e
		puts e
		return 400, e
	end
	response['id']
end

def check_if_descriptors(vnf_id, ns_id)
  begin
		response = JSON.parse(RestClient.get "#{@tenor}/vnfs/{vnf_id}", :content_type => :json)
  rescue RestClient::ExceptionWithResponse => e
    puts e
    response = {'vnfd' => {}}
    response['vnfd']['id'] =  JSON.parse(vnfd)['vnfd']['id']
	rescue => e
		puts e
		puts e.response
		puts e.response.code
		puts e.response.body
		return 400, "Error creating VNF descriptor"
	end
  @e2e[:vnfd_id] = vnf_id

  begin
		response = JSON.parse(RestClient.get "#{@tenor}/network-services/{ns_id}", :content_type => :json)
  rescue RestClient::ExceptionWithResponse => e
    puts e
    response = {'vnfd' => {}}
    response['vnfd']['id'] =  JSON.parse(vnfd)['vnfd']['id']
	rescue => e
		puts e
		puts e.response
		puts e.response.code
		puts e.response.body
		return 400, "Error creating VNF descriptor"
	end
  @e2e[:nsd_id] = ns_id
end

def create_descriptors()
  puts "Creating descriptors"
	vnfd = File.read('vnfd-validator/assets/samples/vnfd_example.json')
	begin
		response = JSON.parse(RestClient.post "#{@tenor}/vnfs", vnfd, :content_type => :json)
  rescue RestClient::ExceptionWithResponse => e
    puts e
    response = {'vnfd' => {}}
    response['vnfd']['id'] =  JSON.parse(vnfd)['vnfd']['id']
	rescue => e
		puts e
		puts e.response
		puts e.response.code
		puts e.response.body
		return 400, "Error creating VNF descriptor"
	end
	vnfd_id = response['vnfd']['id']
	@e2e[:vnfd_id] = response['vnfd']['id']

	nsd = File.read('nsd-validator/assets/samples/nsd_example.json')
	begin
		response = JSON.parse(RestClient.post "#{@tenor}/network-services", nsd, :content_type => :json)
	rescue => e
		puts "Error...."
		puts e
		puts e.response
		puts e.response.code
		puts e.response.body
		return 400, "Error creating VNF descriptor"
	end
	nsd_id = response['nsd']['id']
	 @e2e[:nsd_id] = response['nsd']['id']
	response = {:vnfd_id => vnfd_id, :nsd_id => nsd_id }
	puts response
	return response
end

def delete_descriptors()
	if !@e2e[:nsd_id].nil?
		begin
			response = RestClient.delete "#{@tenor}/network-services/" + @e2e[:nsd_id]
		rescue => e
      puts "Error removing network-service..."
			puts e
		#	puts e.response
		#	puts e.response.code
			#puts e.response.body
			return 400, "Error removing the NS descriptor"
		end
	end
puts "Remving VNFD...."
	if !@e2e[:vnfd_id].nil?
    puts @e2e[:vnfd_id].to_s
    puts "#{@tenor}/vnfs/" + @e2e[:vnfd_id].to_s
		begin
			response = RestClient.delete "#{@tenor}/vnfs/" + @e2e[:vnfd_id].to_s
		rescue => e
			puts e
			puts e.response
			puts e.response.code
			puts e.response.body
			return 400, "Error creating VNF descriptor"
		end
	end
	puts "Descriptors removed correctly."
end

def create_pop(obj)
	begin
		response = JSON.parse(RestClient.post "#{@tenor}/pops/dc", obj.to_json, :content_type => :json)
	rescue => e
		puts "ERROR: "
		puts e
		begin
			response = JSON.parse(RestClient.get "#{@tenor}/pops/dc/name/" + obj[:name])
		rescue => e
			puts "Failed getting PoP."
			return 400, e
		end
	end
	return response['id']
end

def remove_pops_if_exists(pop_name)
  begin
    response = RestClient.get "#{@tenor}/pops/dc/name/#{pop_name}"
  rescue => e
    puts e
    return 400, e
  end
  pop = JSON.parse(response)
  delete_pop(pop['id'])
end

def delete_pop(pop_id)
	response, errors = RestClient.delete "#{@tenor}/pops/dc/#{pop_id}"
	puts errors if errors
	return 400, errors if errors
	puts "Removing PoP.... #{pop_id}"
end

def recover_state(error)
	puts "ERROR DETECTED! Recovering initial state...."
  puts error
	delete_descriptors()
	@e2e[:pops].each do |pop|
		delete_pop(pop[:id])
	end

  @e2e[:instances].each do |instances|
		delete_instance(instances)
	end

	exit
	return 4000
end

puts "Creating end to end tests..."
response, errors = end_to_end_script()
puts "End to end test not completed." if errors
puts errors if errors
exit
puts "End to end test completed."

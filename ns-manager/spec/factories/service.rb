FactoryGirl.define do
	factory :service do
		sequence(:name) { |n| 'name_' + n.to_s }
		host "host_address"
		port "host_port"
		sequence(:token)  { |n| JWT.encode({:service_name => 'name_' + n.to_s}, 'name_' + n.to_s, "HS256") }
		depends_on []
	end
end

FactoryGirl.define do
	factory :service do
		name "test"
		host "host_address"
		port "host_port"
		token "token"
		depends_on []
	end
end

FactoryGirl.define do
	factory :vnfr do
		sequence(:_id) { |n| n.to_s }
		sequence(:lifecycle_info) { |n| {authentication_username: 'test_' + n.to_s, driver: "ssh"} }
		scale_resources []
		stack_url "http://localhost/stackurl"
		deployment_flavour "gold"
	end
end

FactoryGirl.define do
	factory :ns do
		#sequence(:vnf_manager) { |n| 'Manager_' + n.to_s }
		sequence(:nsd) { |n| {id: 'test_' + n.to_s, name: 'test-name'} }
	end
end
FactoryGirl.define do
	factory :nsr do
		sequence(:_id) { |n| n.to_s }
		service_deployment_flavour "gold"
		resource_reservation []
		vnfrs []
	end
end

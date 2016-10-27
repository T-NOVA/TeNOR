FactoryGirl.define do
	factory :dc do
		sequence(:name) { |n| 'name_' + n.to_s }
		host "host2"
	end
end

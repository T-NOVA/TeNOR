FactoryGirl.define do
	factory :statisticModel do
		sequence(:name) { |n| 'name_' + n.to_s }
		value 1
	end
end

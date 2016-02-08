class StatisticModel 
	include Mongoid::Document

	field :name, type: String
 	field :value, type: String
 	index({:name => 1}, {unique: true})
end

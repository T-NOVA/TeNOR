class ServiceModel
	
	include Mongoid::Document

 	field :name, type: String
 	field :host, type: String
 	field :port, type: String
 	field :path, type: String
	field :service_key, type: String
 	index({:name => 1}, {unique: true})
end

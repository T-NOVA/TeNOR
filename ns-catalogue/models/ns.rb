class Ns
	include Mongoid::Document
	include Mongoid::Timestamps
	include Mongoid::Pagination

	field :nsd, type: Hash
	
end

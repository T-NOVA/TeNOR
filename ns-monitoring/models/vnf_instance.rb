=begin
class VnfInstance < ActiveRecord::Base
	belongs_to :ns_monitoring_parameter
	has_many :parameters
	
	def as_json(options={})
		super(
			:except => []
		)
	end
end
=end


class VnfInstance
	include Mongoid::Document
	include Mongoid::Attributes::Dynamic

	belongs_to :ns_monitoring_parameter
	has_many :parameters

end
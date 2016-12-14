=begin
class Parameter  < ActiveRecord::Base
  belongs_to :ns_monitoring_parameter
end

class Parameter
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  belongs_to :ns_monitoring_parameter
  belongs_to :sla
end
=end

class Parameter < ActiveRecord::Base
  belongs_to :sla
  has_many :violations
end

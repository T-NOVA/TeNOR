=begin
class Parameter  < ActiveRecord::Base
  belongs_to :ns_monitoring_parameter
end
=end
class Parameter
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  belongs_to :ns_monitoring_parameter
end

require 'sinatra/activerecord'

class Breach < ActiveRecord::Base
  belongs_to :sla
end

#Breach ID
#Timestamp
#Service ID involved
#VNF ID involved (if any)
#Network link involved (if any)
#Metric ID involved or description
#Associated value

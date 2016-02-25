class PerformanceStatisticModel
  include Mongoid::Document

  field :instance_id, type: String
  field :created_at, type: String
  field :mapping, type: String
  field :instantiation, type: String
  field :total, type: String
  index({:instance_id => 1}, {unique: true})
end

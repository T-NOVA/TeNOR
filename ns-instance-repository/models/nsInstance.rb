module BSON
  class ObjectId
    def to_json(*)
      to_s.to_json
    end
    def as_json(*)
      to_s.as_json
    end
  end
end

module Mongoid
  module Document
    def serializable_hash(options = nil)
      h = super(options)
      h['id'] = h.delete('_id') if(h.has_key?('_id'))
      h
    end
  end
end

class NsInstance
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  field :vnfs, type: Array

  field :nsr_instance, type: Array
  field :ns_id, type: String
  field :status, type: String
  field :version, type: String
  field :vnfrs, type: Array
  field :marketplace_callback, type: String

end

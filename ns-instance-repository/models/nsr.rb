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

class Nsr
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  #field :vnfs, type: Array

#  field :nsr_instance, type: Array
  #ETSI fields
  field :auto_scale_policy, type: Hash
  field :monitoring_parameters, type: Array
  field :service_deployment_flavour, type: String
  field :vendor, type: String
  field :version, type: String
  field :vlr, type: Array
  field :vnfrs, type: Array
  field :lifecycle_event, type: Hash
  field :vnf_dependency, type: Array
  field :vnffgr, type: Array
  field :pnfr, type: Array
  field :descriptor_reference, type: String
  field :descriptor_reservartion, type: Array
  field :runtime_policy_info, type: Array
  field :status, type: String
  field :notification, type: String
  field :lifecycle_event_history, type: Array
  field :audit_log, type: Array

  #TeNOR fields
  field :marketplace_callback, type: String
  field :mapping_time, type: Time
  field :instantiation_start_time, type: Time
  field :instantiation_end_time, type: Time
end

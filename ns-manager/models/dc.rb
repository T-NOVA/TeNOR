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

class Dc
    include Mongoid::Document

    field :name, type: String
    validates :name, presence: true, uniqueness: true
    field :host, type: String
    field :user, type: String
    field :password, type: String
    field :tenant_name, type: String
    field :admin_role, type: Boolean
    field :extra_info, type: String
    field :description, type: String

end

class Service
    include Mongoid::Document

    field :name, type: String
    validates :name, presence: true, uniqueness: true
    field :host, type: String
    field :port, type: String
    field :path, type: String
    field :token, type: String
    field :depends_on, type: Array, default: []
    field :type, type: String
    field :status, type: String
end

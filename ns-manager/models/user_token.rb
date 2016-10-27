class UserToken
    include Mongoid::Document
    include Mongoid::Timestamps
    field :provider,   type: String
    field :uid,        type: String
    field :token,      type: String
    field :expires_at, type: String
    field :expires,    type: Boolean

    belongs_to :user
end

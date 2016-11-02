class User
    include Mongoid::Document
    include Mongoid::Timestamps

    has_many :user_tokens

    field :name, type: String
    attr_accessor :password, :password_confirmation
    field :password_hash, type: String
    field :password_salt, type: String
    validates :email, presence: true,
                      uniqueness: true,
                      format: {
                          with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9\.-]+\.[A-Za-z]+\Z/
                      }
    validates :name, presence: true, uniqueness: true
    validates_presence_of :password, :on => :create
    validates_length_of :password, :minimum => 6, :on => :create

    ## Database authenticatable
    field :email, type: String, default: ''

    field :active, type: Boolean, default: false
    field :is_admin, type: Boolean
    field :roles, type: Array

    ## Trackable
    field :sign_in_count,      type: Integer, default: 0
    field :current_sign_in_at, type: Time
    field :last_sign_in_at,    type: Time
    field :current_sign_in_ip, type: String
    field :last_sign_in_ip,    type: String

    ## Indexes
    index(email: 1, name: 1)
    index(gender: 1, dob: 1, telephone: 1, posts: -1)

    def as_json(options={})
        super(
                #:include => [ :roles, :tenant],
                #:except => [ :password_hash, :password_salt, :activation_hash, :password_reset_hash]
                :except => [ :password_hash, :password_salt]
        )
        end
end

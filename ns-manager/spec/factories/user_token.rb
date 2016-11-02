FactoryGirl.define do
	factory :user_token do
		uid "58107e3e1aa1603094000004"
		token "$2a$10$nZMDkdcjEo3N8kZKEqEs3O"
    expires_at {(Time.now.to_i + (60*60))}
		expires false
	end
end

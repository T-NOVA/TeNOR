FactoryGirl.define do
	factory :user do
		sequence(:name) { |n| 'name_' + n.to_s }
		email "mail@mail.com"
		password "secret"
		password_salt "$2a$10$Rpz5rK4tjpS8TjAft/WvQu"
		password_hash BCrypt::Engine.hash_secret('secret', "$2a$10$Rpz5rK4tjpS8TjAft/WvQu")
		active true
	end
end

FactoryBot.define do
  factory :user do
    sequence(:google_uid) { |n| "google_uid_#{n}" }
    sequence(:email) { |n| "user_#{n}@example.com" }
    name { "Test User" }
  end
end

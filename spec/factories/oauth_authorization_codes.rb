FactoryBot.define do
  factory :oauth_authorization_code do
    user
    sequence(:code_digest) { |n| Digest::SHA256.hexdigest("code-#{n}") }
    sequence(:state_digest) { |n| Digest::SHA256.hexdigest("state-#{n}") }
    expires_at { 2.minutes.from_now }
  end
end

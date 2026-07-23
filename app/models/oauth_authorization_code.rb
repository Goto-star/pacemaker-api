class OauthAuthorizationCode < ApplicationRecord
  belongs_to :user

  validates :code_digest, presence: true, uniqueness: true
  validates :state_digest, :expires_at, presence: true
end

class User < ApplicationRecord
  has_many :materials, dependent: :destroy

  validates :google_uid, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
end

class Material < ApplicationRecord
  belongs_to :user
  has_many :study_units, dependent: :destroy

  validates :title, presence: true
  validates :total_amount, numericality: { greater_than: 0 }, allow_nil: true
end

class StudyUnit < ApplicationRecord
  belongs_to :material

  validates :title, presence: true
  validates :estimated_minutes, numericality: { greater_than: 0 }
  validates :position,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end

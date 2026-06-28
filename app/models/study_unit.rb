class StudyUnit < ApplicationRecord
  belongs_to :material
  has_many :study_logs, dependent: :destroy
  has_many :review_schedules, dependent: :destroy

  validates :title, presence: true
  validates :estimated_minutes, numericality: { greater_than: 0 }
  validates :position,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end

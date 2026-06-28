class ReviewSchedule < ApplicationRecord
  belongs_to :study_unit

  validates :scheduled_on, presence: true
  validates :review_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end

class StudyLog < ApplicationRecord
  belongs_to :study_unit

  # 理解度評価は ★1〜3 の3段階（SM-2 標準の 0〜5 quality は使わない）
  RATING_RANGE = (1..3)

  validates :studied_on, presence: true
  validates :rating,
            numericality: { only_integer: true },
            inclusion: { in: RATING_RANGE }
  validates :duration_minutes,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
end

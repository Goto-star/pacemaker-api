FactoryBot.define do
  factory :review_schedule do
    association :study_unit
    scheduled_on { Date.current + 1 }
    review_count { 0 }
    completed { false }
  end
end

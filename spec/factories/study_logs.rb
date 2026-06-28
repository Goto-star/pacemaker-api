FactoryBot.define do
  factory :study_log do
    association :study_unit
    studied_on { Date.current }
    rating { 3 }
    duration_minutes { 30 }
  end
end

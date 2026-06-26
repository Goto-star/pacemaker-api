FactoryBot.define do
  factory :material do
    association :user
    title { "Test Material" }
    total_amount { 1 }
    unit_label { "section" }
    deadline { "2026-06-25" }
  end
end

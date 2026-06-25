FactoryBot.define do
  factory :study_unit do
    material { nil }
    title { "Test Study Unit" }
    position { 1 }
    estimated_minutes { 1 }
  end
end

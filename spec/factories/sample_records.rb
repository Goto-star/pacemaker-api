# Test-only placeholder so the FactoryBot foundation can be exercised before any
# real ActiveRecord models exist (the first models arrive in a later ticket).
# Replace this with real factories as models land.
class SampleRecord
  attr_accessor :name, :priority

  def initialize(name: nil, priority: nil)
    @name = name
    @priority = priority
  end
end

FactoryBot.define do
  factory :sample_record do
    name { "Sample" }
    priority { 1 }
  end
end

require "rails_helper"

# Smoke test proving the RSpec + FactoryBot test foundation is wired up.
# It intentionally exercises only the tooling, not application behavior;
# real specs ship alongside their features in later tickets.
RSpec.describe "Test foundation" do
  it "runs RSpec examples" do
    expect(1 + 1).to eq(2)
  end

  it "builds objects from a FactoryBot factory" do
    record = build(:sample_record)

    expect(record.name).to eq("Sample")
    expect(record.priority).to eq(1)
  end
end

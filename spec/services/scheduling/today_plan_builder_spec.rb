require "rails_helper"

RSpec.describe Scheduling::TodayPlanBuilder do
  let(:user) { create(:user) }

  def scheduled_ids(result)
    result[:scheduled].map { |item| item[:study_unit].id }
  end

  def all_ids(result)
    (result[:scheduled] + result[:unscheduled]).map { |item| item[:study_unit].id }
  end

  describe "#call" do
    context "復習対象・締切間近の新規・通常の新規が混在する場合" do
      it "優先度順（復習→締切間近→通常）でscheduledに並べること" do
        review_unit = create(:study_unit, estimated_minutes: 10,
                                          material: create(:material, user: user, deadline: nil))
        create(:review_schedule, study_unit: review_unit, scheduled_on: Date.current - 3, completed: false)
        deadline_unit = create(:study_unit, estimated_minutes: 10,
                                            material: create(:material, user: user, deadline: Date.current + 2))
        normal_unit = create(:study_unit, estimated_minutes: 10,
                                          material: create(:material, user: user, deadline: nil))

        result = described_class.new(user: user, available_minutes: 60).call

        expect(scheduled_ids(result)).to eq([ review_unit.id, deadline_unit.id, normal_unit.id ])
      end
    end

    context "複数の復習対象がある場合" do
      it "遅延日数が大きい復習を先にscheduleすること" do
        material = create(:material, user: user, deadline: nil)
        less_overdue = create(:study_unit, material: material, estimated_minutes: 10)
        more_overdue = create(:study_unit, material: material, estimated_minutes: 10)
        create(:review_schedule, study_unit: less_overdue, scheduled_on: Date.current - 1, completed: false)
        create(:review_schedule, study_unit: more_overdue, scheduled_on: Date.current - 5, completed: false)

        result = described_class.new(user: user, available_minutes: 60).call

        expect(scheduled_ids(result)).to eq([ more_overdue.id, less_overdue.id ])
      end
    end

    context "available_minutesに収まらないユニットがある場合" do
      it "収まらない分をunscheduledに回すこと" do
        material = create(:material, user: user, deadline: nil)
        fitting = create(:study_unit, material: material, estimated_minutes: 40)
        overflow = create(:study_unit, material: material, estimated_minutes: 40)

        result = described_class.new(user: user, available_minutes: 50).call

        expect(scheduled_ids(result)).to eq([ fitting.id ])
        expect(result[:unscheduled].map { |item| item[:study_unit].id }).to eq([ overflow.id ])
      end
    end

    context "将来日付の復習だけを持つユニットの場合" do
      it "当日分に含めないこと" do
        material = create(:material, user: user, deadline: nil)
        future_unit = create(:study_unit, material: material, estimated_minutes: 10)
        create(:review_schedule, study_unit: future_unit, scheduled_on: Date.current + 1, completed: false)

        result = described_class.new(user: user, available_minutes: 60).call

        expect(all_ids(result)).not_to include(future_unit.id)
      end
    end

    context "復習が完了済みのユニットの場合" do
      it "当日分に含めないこと" do
        material = create(:material, user: user, deadline: nil)
        done_unit = create(:study_unit, material: material, estimated_minutes: 10)
        create(:review_schedule, study_unit: done_unit, scheduled_on: Date.current - 1, completed: true)

        result = described_class.new(user: user, available_minutes: 60).call

        expect(all_ids(result)).not_to include(done_unit.id)
      end
    end

    context "他ユーザーの教材のユニットがある場合" do
      it "自分の教材のユニットだけを対象にすること" do
        my_unit = create(:study_unit, estimated_minutes: 10,
                                      material: create(:material, user: user, deadline: nil))
        other_unit = create(:study_unit, estimated_minutes: 10)

        result = described_class.new(user: user, available_minutes: 60).call

        expect(scheduled_ids(result)).to eq([ my_unit.id ])
        expect(all_ids(result)).not_to include(other_unit.id)
      end
    end
  end
end

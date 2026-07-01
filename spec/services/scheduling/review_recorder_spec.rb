require "rails_helper"

RSpec.describe Scheduling::ReviewRecorder do
  describe ".call" do
    let!(:study_unit) { create(:study_unit) }
    let!(:studied_on) { Date.new(2026, 7, 1) }

    context "初回学習を★3で記録する場合" do
      it "学習ログと翌日の復習予定を作成すること" do
        result = described_class.call(
          study_unit:,
          attributes: { studied_on:, rating: 3, duration_minutes: 20 }
        )

        expect(result.study_log).to have_attributes(
          studied_on:,
          rating: 3,
          duration_minutes: 20
        )
        expect(result.review_schedule).to have_attributes(
          scheduled_on: studied_on + 1,
          review_count: 1,
          completed: false
        )
      end
    end

    context "予定済みの復習を★3で記録する場合" do
      it "現在の予定を完了し、間隔を延ばした次回予定を作成すること" do
        current_schedule = create(
          :review_schedule,
          study_unit:,
          scheduled_on: studied_on,
          review_count: 1
        )

        result = described_class.call(
          study_unit:,
          attributes: { studied_on:, rating: 3 }
        )

        expect(current_schedule.reload).to be_completed
        expect(result.review_schedule).to have_attributes(
          scheduled_on: studied_on + 6,
          review_count: 2
        )
      end
    end

    context "予定済みの復習を★1で記録する場合" do
      it "翌日に予定し、復習回数をリセットすること" do
        create(
          :review_schedule,
          study_unit:,
          scheduled_on: studied_on,
          review_count: 4
        )

        result = described_class.call(
          study_unit:,
          attributes: { studied_on:, rating: 1 }
        )

        expect(result.review_schedule).to have_attributes(
          scheduled_on: studied_on + 1,
          review_count: 0
        )
      end
    end

    context "学習ログが不正な場合" do
      it "学習ログも復習予定も保存しないこと" do
        expect {
          described_class.call(
            study_unit:,
            attributes: { studied_on: Date.new(2026, 7, 1), rating: 4 }
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(study_unit.study_logs.count).to eq(0)
        expect(study_unit.review_schedules.count).to eq(0)
      end
    end
  end
end

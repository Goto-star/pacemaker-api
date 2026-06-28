# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scheduling::DailyPlanner do
  describe "#call" do
    subject(:plan) do
      described_class.new(
        available_minutes:,
        study_units:
      ).call
    end

    let(:study_unit_class) { Data.define(:id) }

    def unit(id:, minutes:, review: false, overdue_days: 0, deadline_days: nil)
      {
        study_unit: study_unit_class.new(id:),
        estimated_minutes: minutes,
        is_review: review,
        overdue_days:,
        has_deadline: !deadline_days.nil?,
        days_until_deadline: deadline_days || Float::INFINITY
      }
    end

    def scheduled_ids
      plan.fetch(:scheduled).map { |item| item.fetch(:study_unit).id }
    end

    def unscheduled_ids
      plan.fetch(:unscheduled).map { |item| item.fetch(:study_unit).id }
    end

    context "復習・締切ありの新規・締切なしの新規が混在する場合" do
      let(:available_minutes) { 60 }
      let(:study_units) do
        [
          unit(id: 5, minutes: 15),
          unit(id: 4, minutes: 15, deadline_days: 2),
          unit(id: 3, minutes: 15, review: true, overdue_days: 1),
          unit(id: 2, minutes: 15, deadline_days: 1),
          unit(id: 1, minutes: 15, review: true, overdue_days: 3)
        ]
      end

      it "復習・締切間近の新規・通常の新規の順に予定すること" do
        expect(scheduled_ids).to eq([ 1, 3, 2, 4 ])
      end

      it "可処分時間に収まらない学習単位を未予定にすること" do
        expect(unscheduled_ids).to eq([ 5 ])
      end

      it "戻り値に呼び出し側向けの属性だけを含めること" do
        expect(plan.fetch(:scheduled).first.keys).to contain_exactly(:study_unit, :estimated_minutes)
      end
    end

    context "復習だけがある場合" do
      let(:available_minutes) { 30 }
      let(:study_units) do
        [
          unit(id: 1, minutes: 10, review: true, overdue_days: 1),
          unit(id: 2, minutes: 10, review: true, overdue_days: 5),
          unit(id: 3, minutes: 10, review: true, overdue_days: 3)
        ]
      end

      it "遅延日数の降順に予定すること" do
        expect(scheduled_ids).to eq([ 2, 3, 1 ])
      end
    end

    context "新規だけがある場合" do
      let(:available_minutes) { 40 }
      let(:study_units) do
        [
          unit(id: 4, minutes: 10),
          unit(id: 3, minutes: 10, deadline_days: 5),
          unit(id: 2, minutes: 10),
          unit(id: 1, minutes: 10, deadline_days: 2)
        ]
      end

      it "締切が近い順の後に締切なしを登録順で予定すること" do
        expect(scheduled_ids).to eq([ 1, 3, 2, 4 ])
      end
    end

    context "可処分時間が0分の場合" do
      let(:available_minutes) { 0 }
      let(:study_units) { [ unit(id: 1, minutes: 10) ] }

      it "すべての学習単位を未予定にすること" do
        expect(plan).to eq(
          scheduled: [],
          unscheduled: [
            {
              study_unit: study_units.first.fetch(:study_unit),
              estimated_minutes: 10
            }
          ]
        )
      end
    end

    context "学習時間が可処分時間にちょうど収まる場合" do
      let(:available_minutes) { 30 }
      let(:study_units) { [ unit(id: 1, minutes: 30) ] }

      it "学習単位を予定すること" do
        expect(scheduled_ids).to eq([ 1 ])
      end
    end

    context "学習時間に対して可処分時間が1分足りない場合" do
      let(:available_minutes) { 29 }
      let(:study_units) { [ unit(id: 1, minutes: 30) ] }

      it "学習単位を未予定にすること" do
        expect(unscheduled_ids).to eq([ 1 ])
      end
    end

    context "優先度の高い学習単位が収まらず後続が収まる場合" do
      let(:available_minutes) { 20 }
      let(:study_units) do
        [
          unit(id: 1, minutes: 30, review: true, overdue_days: 2),
          unit(id: 2, minutes: 20)
        ]
      end

      it "先頭を未予定にして後続を予定すること" do
        expect(plan).to match(
          scheduled: [ hash_including(study_unit: study_units.last.fetch(:study_unit)) ],
          unscheduled: [ hash_including(study_unit: study_units.first.fetch(:study_unit)) ]
        )
      end
    end
  end
end

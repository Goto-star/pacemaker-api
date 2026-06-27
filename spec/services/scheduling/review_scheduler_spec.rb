# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scheduling::ReviewScheduler do
  describe ".call" do
    subject(:next_review_date) do
      described_class.call(
        previous_review_date: Date.new(2026, 6, 27),
        review_count:,
        rating:
      )
    end

    context "初回の復習の場合" do
      let(:review_count) { 0 }
      let(:rating) { 3 }

      it "次回復習日が翌日になること" do
        expect(next_review_date).to eq(Date.new(2026, 6, 28))
      end
    end

    context "2回目の復習に成功した場合" do
      let(:review_count) { 1 }
      let(:rating) { 2 }

      it "次回復習日が6日後になること" do
        expect(next_review_date).to eq(Date.new(2026, 7, 3))
      end
    end

    context "復習に複数回成功した後に★3と評価した場合" do
      let(:review_count) { 2 }
      let(:rating) { 3 }

      it "復習間隔が大きく伸びること" do
        expect(next_review_date).to eq(Date.new(2026, 7, 13))
      end
    end

    context "復習に複数回成功した後に★2と評価した場合" do
      let(:review_count) { 2 }
      let(:rating) { 2 }

      it "復習間隔が標準的に伸びること" do
        expect(next_review_date).to eq(Date.new(2026, 7, 9))
      end
    end

    context "復習に複数回成功した後に★1と評価した場合" do
      let(:review_count) { 5 }
      let(:rating) { 1 }

      it "復習間隔が1日にリセットされること" do
        expect(next_review_date).to eq(Date.new(2026, 6, 28))
      end
    end

    context "3段階の範囲外の評価を渡した場合" do
      let(:review_count) { 1 }
      let(:rating) { 4 }

      it "評価が不正であることを通知すること" do
        expect { next_review_date }
          .to raise_error(ArgumentError, "rating must be between 1 and 3")
      end
    end

    context "負の復習回数を渡した場合" do
      let(:review_count) { -1 }
      let(:rating) { 2 }

      it "復習回数が不正であることを通知すること" do
        expect { next_review_date }
          .to raise_error(ArgumentError, "review_count must be a non-negative Integer")
      end
    end
  end
end

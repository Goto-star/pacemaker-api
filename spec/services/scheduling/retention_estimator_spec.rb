# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scheduling::RetentionEstimator do
  describe ".call" do
    let(:base_date) { Date.new(2026, 6, 27) }

    context "復習履歴が空の場合" do
      it "定着度を0.0として返すこと" do
        expect(described_class.call(reviews: [], as_of: base_date)).to eq(0.0)
      end
    end

    context "当日に復習した直後の場合" do
      it "定着度を最大値1.0として返すこと" do
        reviews = [ { rating: 3, reviewed_on: base_date } ]

        expect(described_class.call(reviews:, as_of: base_date)).to eq(1.0)
      end
    end

    context "最終復習日より前の日付を基準日に渡した場合" do
      it "定着度を1.0にクランプすること" do
        reviews = [ { rating: 3, reviewed_on: base_date } ]

        expect(described_class.call(reviews:, as_of: base_date - 5)).to eq(1.0)
      end
    end

    context "★3で1回復習し時間が経過した場合" do
      it "忘却曲線 exp(-経過日数/安定度) に従って減衰すること" do
        reviews = [ { rating: 3, reviewed_on: base_date } ]

        expect(described_class.call(reviews:, as_of: base_date + 5))
          .to be_within(1e-9).of(Math.exp(-5.0 / 2.5))
      end
    end

    context "★3を重ねた履歴の場合" do
      it "★1でリセットした履歴より同じ経過日数での定着度が高いこと" do
        strong = [
          { rating: 3, reviewed_on: base_date },
          { rating: 3, reviewed_on: base_date + 1 },
          { rating: 3, reviewed_on: base_date + 2 }
        ]
        reset = [
          { rating: 3, reviewed_on: base_date },
          { rating: 3, reviewed_on: base_date + 1 },
          { rating: 1, reviewed_on: base_date + 2 }
        ]
        as_of = base_date + 12

        expect(described_class.call(reviews: strong, as_of:))
          .to be > described_class.call(reviews: reset, as_of:)
      end
    end

    context "最後の評価が★1の場合" do
      it "安定度が基準値にリセットされること" do
        reviews = [
          { rating: 3, reviewed_on: base_date },
          { rating: 3, reviewed_on: base_date + 1 },
          { rating: 1, reviewed_on: base_date + 2 }
        ]

        expect(described_class.call(reviews:, as_of: base_date + 3))
          .to be_within(1e-9).of(Math.exp(-1.0))
      end
    end

    context "経過日数が長くなるほど" do
      it "定着度が単調に低下すること" do
        reviews = [ { rating: 3, reviewed_on: base_date } ]
        sooner = described_class.call(reviews:, as_of: base_date + 5)
        later = described_class.call(reviews:, as_of: base_date + 30)

        expect(sooner).to be > later
      end
    end

    context "極端に時間が経過した場合" do
      it "定着度が0.0〜1.0の値域に収まること" do
        reviews = [ { rating: 3, reviewed_on: base_date } ]
        retention = described_class.call(reviews:, as_of: base_date + 10_000)

        expect(retention).to be_between(0.0, 1.0).inclusive
      end
    end

    context "復習履歴が日付順に並んでいない場合" do
      it "並び順に依存せず同じ定着度を返すこと" do
        ordered = [
          { rating: 3, reviewed_on: base_date },
          { rating: 3, reviewed_on: base_date + 1 },
          { rating: 1, reviewed_on: base_date + 2 }
        ]
        unordered = [
          { rating: 1, reviewed_on: base_date + 2 },
          { rating: 3, reviewed_on: base_date },
          { rating: 3, reviewed_on: base_date + 1 }
        ]
        as_of = base_date + 3

        expect(described_class.call(reviews: unordered, as_of:))
          .to eq(described_class.call(reviews: ordered, as_of:))
      end
    end

    context "★1〜3の範囲外の評価を含む場合" do
      it "評価が不正であることを通知すること" do
        reviews = [ { rating: 4, reviewed_on: base_date } ]

        expect { described_class.call(reviews:, as_of: base_date) }
          .to raise_error(ArgumentError, "rating must be between 1 and 3")
      end
    end

    context "復習日がDateでない場合" do
      it "復習日が不正であることを通知すること" do
        reviews = [ { rating: 2, reviewed_on: "2026-06-27" } ]

        expect { described_class.call(reviews:, as_of: base_date) }
          .to raise_error(ArgumentError, "reviewed_on must be a Date")
      end
    end

    context "reviewsが配列でない場合" do
      it "reviewsが不正であることを通知すること" do
        expect { described_class.call(reviews: nil, as_of: base_date) }
          .to raise_error(ArgumentError, "reviews must be an Array")
      end
    end

    context "基準日がDateでない場合" do
      it "基準日が不正であることを通知すること" do
        expect { described_class.call(reviews: [], as_of: "2026-06-27") }
          .to raise_error(ArgumentError, "as_of must be a Date")
      end
    end
  end
end

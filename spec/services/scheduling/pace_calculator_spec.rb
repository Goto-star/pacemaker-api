# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scheduling::PaceCalculator do
  describe ".call" do
    let(:base_date) { Date.new(2026, 6, 28) }

    context "残10ユニットで締切まで当日含め5日ある場合" do
      it "残ユニット÷残日数の1日ノルマを返すこと" do
        expect(described_class.call(remaining_amount: 10, deadline: base_date + 4, as_of: base_date))
          .to eq(2)
      end
    end

    context "残ユニットが残日数で割り切れない場合" do
      it "締切までに終わるよう切り上げた1日ノルマを返すこと" do
        expect(described_class.call(remaining_amount: 10, deadline: base_date + 2, as_of: base_date))
          .to eq(4)
      end
    end

    context "締切が当日の場合" do
      it "残ユニットすべてを当日のノルマとして返すこと" do
        expect(described_class.call(remaining_amount: 7, deadline: base_date, as_of: base_date))
          .to eq(7)
      end
    end

    context "締切を過ぎている場合" do
      it "残ユニットすべてを当日のノルマとして返すこと" do
        expect(described_class.call(remaining_amount: 7, deadline: base_date - 3, as_of: base_date))
          .to eq(7)
      end
    end

    context "締切がない教材の場合" do
      it "ノルマを課さずnilを返すこと" do
        expect(described_class.call(remaining_amount: 10, deadline: nil, as_of: base_date))
          .to be_nil
      end
    end

    context "残ユニットが0の場合" do
      it "1日ノルマを0として返すこと" do
        expect(described_class.call(remaining_amount: 0, deadline: base_date + 4, as_of: base_date))
          .to eq(0)
      end
    end

    context "as_ofを省略した場合" do
      it "当日を基準に算出すること" do
        expect(described_class.call(remaining_amount: 6, deadline: Date.current + 2))
          .to eq(2)
      end
    end

    context "残ユニットが非負の整数でない場合" do
      it "残ユニットが不正であることを通知すること" do
        expect { described_class.call(remaining_amount: -1, deadline: base_date, as_of: base_date) }
          .to raise_error(ArgumentError, "remaining_amount must be a non-negative Integer")
      end
    end

    context "締切がDateでもnilでもない場合" do
      it "締切が不正であることを通知すること" do
        expect { described_class.call(remaining_amount: 10, deadline: "2026-06-28", as_of: base_date) }
          .to raise_error(ArgumentError, "deadline must be a Date or nil")
      end
    end

    context "基準日がDateでない場合" do
      it "基準日が不正であることを通知すること" do
        expect { described_class.call(remaining_amount: 10, deadline: base_date, as_of: "2026-06-28") }
          .to raise_error(ArgumentError, "as_of must be a Date")
      end
    end
  end
end

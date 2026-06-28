# frozen_string_literal: true

module Scheduling
  # 締切から逆算して「1日あたりやるべき量（1日ノルマ）」を算出する。
  # 残ユニット ÷ 残日数 が基本式。締切なしの教材はノルマを課さない（nil）。
  class PaceCalculator
    MINIMUM_DAYS = 1

    def self.call(remaining_amount:, deadline:, as_of: Date.current)
      new(remaining_amount:, deadline:, as_of:).call
    end

    def initialize(remaining_amount:, deadline:, as_of: Date.current)
      @remaining_amount = remaining_amount
      @deadline = deadline
      @as_of = as_of
    end

    def call
      validate_inputs!

      # 締切がない教材はノルマを課さない
      return nil if deadline.nil?
      return 0 if remaining_amount.zero?

      (remaining_amount.to_f / remaining_days).ceil
    end

    private

    attr_reader :remaining_amount, :deadline, :as_of

    # 当日を含めた残日数。締切超過の場合も最低1日分として今日やり切る量を返す。
    def remaining_days
      [ (deadline - as_of).to_i + 1, MINIMUM_DAYS ].max
    end

    def validate_inputs!
      unless remaining_amount.is_a?(Integer) && remaining_amount >= 0
        raise ArgumentError, "remaining_amount must be a non-negative Integer"
      end
      raise ArgumentError, "deadline must be a Date or nil" unless deadline.nil? || deadline.is_a?(Date)
      raise ArgumentError, "as_of must be a Date" unless as_of.is_a?(Date)
    end
  end
end

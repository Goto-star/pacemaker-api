# frozen_string_literal: true

module Scheduling
  class ReviewScheduler
    INITIAL_INTERVAL_DAYS = 1
    SECOND_INTERVAL_DAYS = 6
    RESET_RATING = 1
    VALID_RATINGS = (1..3)
    # ★ごとに覚えやすさ係数を PaceMaker 側で直接定義する（SM-2 標準の 0〜5 quality は使わない）
    # ★1 は interval_days でリセットされるため EF は不要
    EASINESS_FACTOR_BY_RATING = {
      2 => 2.0,
      3 => 2.6
    }.freeze

    def self.call(previous_review_date:, review_count:, rating:)
      new(
        previous_review_date:,
        review_count:,
        rating:
      ).call
    end

    def initialize(previous_review_date:, review_count:, rating:)
      @previous_review_date = previous_review_date
      @review_count = review_count
      @rating = rating
    end

    def call
      validate_inputs!

      previous_review_date + interval_days
    end

    private

    attr_reader :previous_review_date, :review_count, :rating

    def interval_days
      return INITIAL_INTERVAL_DAYS if rating == RESET_RATING || review_count.zero?
      return SECOND_INTERVAL_DAYS if review_count == 1

      (SECOND_INTERVAL_DAYS * easiness_factor**(review_count - 1)).round
    end

    def easiness_factor
      EASINESS_FACTOR_BY_RATING.fetch(rating)
    end

    def validate_inputs!
      raise ArgumentError, "previous_review_date must be a Date" unless previous_review_date.is_a?(Date)
      raise ArgumentError, "review_count must be a non-negative Integer" unless review_count.is_a?(Integer) && review_count >= 0
      raise ArgumentError, "rating must be between 1 and 3" unless VALID_RATINGS.include?(rating)
    end
  end
end

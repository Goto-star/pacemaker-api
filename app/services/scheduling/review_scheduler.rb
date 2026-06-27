# frozen_string_literal: true

module Scheduling
  class ReviewScheduler
    INITIAL_INTERVAL_DAYS = 1
    SECOND_INTERVAL_DAYS = 6
    INITIAL_EASINESS_FACTOR = 2.5
    MINIMUM_EASINESS_FACTOR = 1.3
    QUALITY_BY_RATING = {
      1 => 1,
      2 => 3,
      3 => 5
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
      return INITIAL_INTERVAL_DAYS if rating == 1 || review_count.zero?
      return SECOND_INTERVAL_DAYS if review_count == 1

      (SECOND_INTERVAL_DAYS * easiness_factor**(review_count - 1)).round
    end

    def easiness_factor
      quality = QUALITY_BY_RATING.fetch(rating)
      adjustment = 0.1 - ((5 - quality) * (0.08 + ((5 - quality) * 0.02)))

      [ INITIAL_EASINESS_FACTOR + adjustment, MINIMUM_EASINESS_FACTOR ].max
    end

    def validate_inputs!
      raise ArgumentError, "previous_review_date must be a Date" unless previous_review_date.is_a?(Date)
      raise ArgumentError, "review_count must be a non-negative Integer" unless review_count.is_a?(Integer) && review_count >= 0
      raise ArgumentError, "rating must be between 1 and 3" unless QUALITY_BY_RATING.key?(rating)
    end
  end
end

# frozen_string_literal: true

module Scheduling
  class RetentionEstimator
    BASE_STABILITY_DAYS = 1.0
    STABILITY_GROWTH_BY_RATING = {
      1 => :reset,
      2 => 1.5,
      3 => 2.5
    }.freeze
    MIN_RETENTION = 0.0
    MAX_RETENTION = 1.0
    VALID_RATINGS = (1..3)

    def self.call(reviews:, as_of: Date.current)
      new(reviews:, as_of:).call
    end

    def initialize(reviews:, as_of: Date.current)
      @reviews = reviews
      @as_of = as_of
    end

    def call
      validate_inputs!
      return MIN_RETENTION if reviews.empty?

      Math.exp(-elapsed_days.to_f / stability_days).clamp(MIN_RETENTION, MAX_RETENTION)
    end

    private

    attr_reader :reviews, :as_of

    def elapsed_days
      (as_of - reviews.map { |review| review.fetch(:reviewed_on) }.max).to_i
    end

    def stability_days
      reviews
        .sort_by { |review| review.fetch(:reviewed_on) }
        .reduce(BASE_STABILITY_DAYS) do |stability, review|
          growth = STABILITY_GROWTH_BY_RATING.fetch(review.fetch(:rating))
          growth == :reset ? BASE_STABILITY_DAYS : stability * growth
        end
    end

    def validate_inputs!
      raise ArgumentError, "reviews must be an Array" unless reviews.is_a?(Array)
      raise ArgumentError, "as_of must be a Date" unless as_of.is_a?(Date)

      reviews.each do |review|
        raise ArgumentError, "each review must be a Hash" unless review.is_a?(Hash)
        raise ArgumentError, "rating must be between 1 and 3" unless VALID_RATINGS.include?(review[:rating])
        raise ArgumentError, "reviewed_on must be a Date" unless review[:reviewed_on].is_a?(Date)
      end
    end
  end
end

# frozen_string_literal: true

module Scheduling
  class ReviewRecorder
    Result = Data.define(:study_log, :review_schedule)
    RESET_RATING = 1

    def self.call(study_unit:, attributes:)
      new(study_unit:, attributes:).call
    end

    def initialize(study_unit:, attributes:)
      @study_unit = study_unit
      @attributes = attributes
    end

    def call
      study_unit.with_lock do
        study_log = study_unit.study_logs.create!(attributes)
        current_schedule = current_schedule_for(study_log.studied_on)
        review_count = current_schedule&.review_count || 0

        current_schedule&.update!(completed: true)

        next_schedule = study_unit.review_schedules.create!(
          scheduled_on: ReviewScheduler.call(
            previous_review_date: study_log.studied_on,
            review_count:,
            rating: study_log.rating
          ),
          review_count: next_review_count(review_count, study_log.rating)
        )

        Result.new(study_log:, review_schedule: next_schedule)
      end
    end

    private

    attr_reader :study_unit, :attributes

    def current_schedule_for(studied_on)
      study_unit.review_schedules
        .where(completed: false, scheduled_on: ..studied_on)
        .order(scheduled_on: :desc, id: :desc)
        .first
    end

    def next_review_count(review_count, rating)
      return 0 if rating == RESET_RATING

      review_count + 1
    end
  end
end

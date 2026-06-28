# frozen_string_literal: true

module Scheduling
  class DailyPlanner
    def initialize(available_minutes:, study_units:)
      @available_minutes = available_minutes
      @study_units = study_units
    end

    def call
      remaining_minutes = available_minutes
      scheduled = []
      unscheduled = []

      prioritized_study_units.each do |unit|
        destination = unit.fetch(:estimated_minutes) <= remaining_minutes ? scheduled : unscheduled
        destination << result_item(unit)
        remaining_minutes -= unit.fetch(:estimated_minutes) if destination.equal?(scheduled)
      end

      { scheduled:, unscheduled: }
    end

    private

    attr_reader :available_minutes, :study_units

    def prioritized_study_units
      study_units.sort_by do |unit|
        if unit.fetch(:is_review)
          [ 0, -unit.fetch(:overdue_days), unit.fetch(:study_unit).id ]
        elsif unit.fetch(:has_deadline)
          [ 1, unit.fetch(:days_until_deadline), unit.fetch(:study_unit).id ]
        else
          [ 2, unit.fetch(:study_unit).id ]
        end
      end
    end

    def result_item(unit)
      unit.slice(:study_unit, :estimated_minutes)
    end
  end
end

# frozen_string_literal: true

module Scheduling
  # ユーザーの学習ユニットから DailyPlanner 用のメタ情報を組み立て、
  # 当日分のプラン（scheduled / unscheduled）を返す。
  #
  # DailyPlanner は「受け取った配列をソート・詰め込むだけ」なので、
  # 復習対象の判定や締切残日数などの DB クエリはこの呼び出し側の責務。
  class TodayPlanBuilder
    def initialize(user:, available_minutes:, today: Date.current)
      @user = user
      @available_minutes = available_minutes
      @today = today
    end

    def call
      DailyPlanner.new(
        available_minutes: available_minutes,
        study_units: study_units_with_meta
      ).call
    end

    private

    attr_reader :user, :available_minutes, :today

    def study_units_with_meta
      candidates = candidate_study_units.to_a
      review_meta(candidates) + new_unit_meta_for_daily_pace(candidates)
    end

    def candidate_study_units
      StudyUnit
        .joins(:material)
        .where(materials: { user_id: user.id })
        .includes(:material, :review_schedules)
    end

    # 復習は当日以前の未完了分をすべて候補にする。新規学習は教材ごとに
    # PaceCalculator が算出した当日ノルマまでに絞り、その後に
    # DailyPlanner が可処分時間へ収まるものを選ぶ。
    def review_meta(candidates)
      candidates.filter_map do |study_unit|
        next if study_unit.review_schedules.empty?

        due = due_review_schedule(study_unit)
        review_unit_meta(study_unit, due) if due
      end
    end

    def new_unit_meta_for_daily_pace(candidates)
      candidates
        .select { |study_unit| study_unit.review_schedules.empty? }
        .group_by(&:material_id)
        .flat_map { |_material_id, study_units| paced_new_units(study_units) }
        .map { |study_unit| new_unit_meta(study_unit) }
    end

    def paced_new_units(study_units)
      ordered_units = study_units.sort_by { |study_unit| [ study_unit.position, study_unit.id ] }
      daily_amount = PaceCalculator.call(
        remaining_amount: ordered_units.length,
        deadline: ordered_units.first.material.deadline,
        as_of: today
      )

      daily_amount.nil? ? ordered_units : ordered_units.first(daily_amount)
    end

    def due_review_schedule(study_unit)
      study_unit.review_schedules
                .reject(&:completed)
                .select { |schedule| schedule.scheduled_on <= today }
                .min_by(&:scheduled_on)
    end

    def review_unit_meta(study_unit, schedule)
      base_meta(study_unit).merge(
        is_review: true,
        overdue_days: (today - schedule.scheduled_on).to_i
      )
    end

    def new_unit_meta(study_unit)
      base_meta(study_unit).merge(
        is_review: false,
        overdue_days: 0
      )
    end

    def base_meta(study_unit)
      deadline = study_unit.material.deadline
      {
        study_unit: study_unit,
        estimated_minutes: study_unit.estimated_minutes,
        has_deadline: deadline.present?,
        days_until_deadline: deadline ? (deadline - today).to_i : Float::INFINITY
      }
    end
  end
end

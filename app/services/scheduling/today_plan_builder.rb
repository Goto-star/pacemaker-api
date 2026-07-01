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
      candidate_study_units.filter_map { |study_unit| meta_for(study_unit) }
    end

    def candidate_study_units
      StudyUnit
        .joins(:material)
        .where(materials: { user_id: user.id })
        .includes(:material, :review_schedules)
    end

    # 当日分に含めるのは「復習が今日以前に予定されているユニット」と
    # 「まだ一度も学習していない新規ユニット」。将来日付の復習待ちや
    # 復習完了済みのユニットは当日分から除外する。
    def meta_for(study_unit)
      if study_unit.review_schedules.empty?
        new_unit_meta(study_unit)
      else
        due = due_review_schedule(study_unit)
        due && review_unit_meta(study_unit, due)
      end
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

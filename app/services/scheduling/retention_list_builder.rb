# frozen_string_literal: true

module Scheduling
  # ユーザーの学習ユニットごとに、学習ログから推定定着度を算出して一覧化する。
  # 定着度の算出そのものは RetentionEstimator（Order 114）に委譲し、
  # ここは DB からの取得・入力整形・並び替えだけを担う。
  class RetentionListBuilder
    RETENTION_PRECISION = 2

    def initialize(user:, as_of: Date.current)
      @user = user
      @as_of = as_of
    end

    def call
      study_units.map { |study_unit| retention_entry(study_unit) }
    end

    private

    attr_reader :user, :as_of

    def study_units
      StudyUnit
        .joins(:material)
        .where(materials: { user_id: user.id })
        .includes(:study_logs)
        .order(:material_id, :position, :id)
    end

    def retention_entry(study_unit)
      {
        study_unit: study_unit,
        retention: estimate_retention(study_unit)
      }
    end

    def estimate_retention(study_unit)
      reviews = study_unit.study_logs.map do |log|
        { reviewed_on: log.studied_on, rating: log.rating }
      end

      RetentionEstimator.call(reviews: reviews, as_of: as_of).round(RETENTION_PRECISION)
    end
  end
end

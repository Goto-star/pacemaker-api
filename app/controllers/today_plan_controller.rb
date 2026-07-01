class TodayPlanController < ApplicationController
  include Authenticatable

  DEFAULT_AVAILABLE_MINUTES = 60

  def show
    plan = Scheduling::TodayPlanBuilder.new(
      user: current_user,
      available_minutes: available_minutes
    ).call

    render json: {
      available_minutes: available_minutes,
      scheduled: plan[:scheduled].map { |item| plan_item_json(item) },
      unscheduled: plan[:unscheduled].map { |item| plan_item_json(item) }
    }
  end

  private

  def available_minutes
    @available_minutes ||= params[:available_minutes].presence&.to_i || DEFAULT_AVAILABLE_MINUTES
  end

  def plan_item_json(item)
    study_unit = item[:study_unit]
    {
      study_unit: {
        id: study_unit.id,
        material_id: study_unit.material_id,
        title: study_unit.title,
        position: study_unit.position,
        estimated_minutes: study_unit.estimated_minutes
      },
      estimated_minutes: item[:estimated_minutes]
    }
  end
end

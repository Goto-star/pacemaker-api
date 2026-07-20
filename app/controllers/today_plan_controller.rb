class TodayPlanController < ApplicationController
  include Authenticatable

  DEFAULT_AVAILABLE_MINUTES = 60
  AVAILABLE_MINUTES_RANGE = (0..1_440)

  def show
    return render_invalid_available_minutes if available_minutes.nil?

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
    return @available_minutes if defined?(@available_minutes)
    return @available_minutes = DEFAULT_AVAILABLE_MINUTES if params[:available_minutes].blank?

    parsed_value = Integer(params[:available_minutes], exception: false)
    @available_minutes = parsed_value if AVAILABLE_MINUTES_RANGE.cover?(parsed_value)
  end

  def render_invalid_available_minutes
    render json: {
      error: "available_minutes must be an integer between 0 and 1440"
    }, status: :unprocessable_content
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

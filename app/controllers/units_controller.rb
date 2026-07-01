class UnitsController < ApplicationController
  include Authenticatable

  def review
    result = Scheduling::ReviewRecorder.call(
      study_unit: StudyUnit.joins(:material).find_by!(
        id: params[:id],
        materials: { user_id: current_user.id }
      ),
      attributes: review_params.to_h.symbolize_keys
    )

    render json: {
      study_log: result.study_log.as_json(only: %i[id study_unit_id studied_on rating duration_minutes]),
      review_schedule: result.review_schedule.as_json(
        only: %i[id study_unit_id scheduled_on review_count completed]
      )
    }, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Study unit not found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.to_hash }, status: :unprocessable_content
  end

  private

  def review_params
    params.require(:review).permit(:studied_on, :rating, :duration_minutes)
  end
end

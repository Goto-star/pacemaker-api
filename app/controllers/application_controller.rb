class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_not_found
    render json: { error: "Not Found" }, status: :not_found
  end

  def render_unprocessable(record)
    render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
  end
end

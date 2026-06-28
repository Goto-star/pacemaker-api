module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    render_unauthorized if current_user.nil?
  end

  def current_user
    @current_user ||= resolve_current_user
  end

  def resolve_current_user
    payload = Authentication::JsonWebToken.decode(bearer_token)
    return if payload.nil?

    User.find_by(id: payload[:user_id])
  end

  def bearer_token
    request.authorization&.split&.last
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end

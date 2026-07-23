module Auth
  class OmniauthCallbacksController < ApplicationController
    rescue_from ActiveRecord::RecordInvalid, KeyError, ArgumentError, with: :render_invalid_auth

    def create
      user = Authentication::GoogleUserResolver.call(request.env.fetch("omniauth.auth"))
      frontend_state = session.delete(:frontend_oauth_state)
      raise ArgumentError, "missing frontend OAuth state" if frontend_state.blank?

      authorization_code = Authentication::AuthorizationCode.issue(user:, frontend_state:)

      redirect_to frontend_callback_url(authorization_code, frontend_state), allow_other_host: true
    end

    def failure
      render json: { error: "OAuth authentication failed" }, status: :unauthorized
    end

    private

    def frontend_callback_url(authorization_code, frontend_state)
      uri = URI.parse(Rails.application.config.x.frontend_origin)
      uri.path = "/auth/callback"
      uri.query = URI.encode_www_form(code: authorization_code, state: frontend_state)
      uri.fragment = nil
      uri.to_s
    end

    def render_invalid_auth
      render json: { error: "Invalid OAuth response" }, status: :unprocessable_content
    end
  end
end

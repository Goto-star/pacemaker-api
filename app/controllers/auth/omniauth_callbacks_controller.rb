module Auth
  class OmniauthCallbacksController < ApplicationController
    rescue_from ActiveRecord::RecordInvalid, KeyError, ArgumentError, with: :render_invalid_auth

    def create
      user = Authentication::GoogleUserResolver.call(request.env.fetch("omniauth.auth"))
      token = Authentication::JsonWebToken.encode({ user_id: user.id })

      redirect_to frontend_callback_url(token), allow_other_host: true
    end

    def failure
      render json: { error: "OAuth authentication failed" }, status: :unauthorized
    end

    private

    def frontend_callback_url(token)
      uri = URI.parse(Rails.application.config.x.frontend_origin)
      uri.path = "/auth/callback"
      uri.query = URI.encode_www_form(token: token)
      uri.fragment = nil
      uri.to_s
    end

    def render_invalid_auth
      render json: { error: "Invalid OAuth response" }, status: :unprocessable_entity
    end
  end
end

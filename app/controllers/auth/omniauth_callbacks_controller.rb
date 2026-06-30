module Auth
  class OmniauthCallbacksController < ApplicationController
    rescue_from ActiveRecord::RecordInvalid, KeyError, ArgumentError, with: :render_invalid_auth

    def create
      user = Authentication::GoogleUserResolver.call(request.env.fetch("omniauth.auth"))
      token = Authentication::JsonWebToken.encode({ user_id: user.id })

      render json: {
        token: token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name
        }
      }
    end

    def failure
      render json: { error: "OAuth authentication failed" }, status: :unauthorized
    end

    private

    def render_invalid_auth
      render json: { error: "Invalid OAuth response" }, status: :unprocessable_entity
    end
  end
end

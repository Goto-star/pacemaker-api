module Auth
  class TokensController < ApplicationController
    rescue_from Authentication::AuthorizationCode::InvalidCode, with: :render_invalid_code

    def create
      user = Authentication::AuthorizationCode.consume(
        code: params.require(:code),
        frontend_state: params.require(:state)
      )

      render json: { token: Authentication::JsonWebToken.encode({ user_id: user.id }) }
    end

    private

    def render_invalid_code
      render json: { error: "Invalid authorization code" }, status: :unauthorized
    end
  end
end

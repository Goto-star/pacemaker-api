module Auth
  class DevelopmentLoginsController < ApplicationController
    rescue_from Authentication::DevelopmentUserResolver::DisabledEnvironment, with: :render_not_found

    def create
      user = Authentication::DevelopmentUserResolver.call
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

    private

    def render_not_found
      render json: { error: "Not Found" }, status: :not_found
    end
  end
end

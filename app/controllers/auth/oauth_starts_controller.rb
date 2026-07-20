module Auth
  class OauthStartsController < ApplicationController
    FRONTEND_STATE_PATTERN = /\A[A-Za-z0-9_-]{43,128}\z/

    def create
      frontend_state = params[:state].to_s
      unless FRONTEND_STATE_PATTERN.match?(frontend_state)
        return render json: { error: "Invalid OAuth state" }, status: :unprocessable_content
      end

      session[:frontend_oauth_state] = frontend_state
      redirect_to "/auth/google_oauth2"
    end
  end
end

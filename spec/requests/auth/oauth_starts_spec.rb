require "rails_helper"

RSpec.describe "OAuth開始", type: :request do
  describe "GET /auth/start" do
    it "妥当なstateをセッションへ保存してGoogle OAuthへリダイレクトする" do
      state = SecureRandom.urlsafe_base64(32)

      get "/auth/start", params: { state: }

      expect(response).to redirect_to("/auth/google_oauth2")
    end

    it "短すぎるstateを拒否する" do
      get "/auth/start", params: { state: "short" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "Invalid OAuth state")
    end
  end
end

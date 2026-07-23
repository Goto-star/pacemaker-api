require "rails_helper"

RSpec.describe "OAuth開始", type: :request do
  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
  end

  describe "GET /auth/start" do
    it "妥当なstateを保存し、CSRF保護されたPOSTフォームでGoogle OAuthを開始する" do
      state = SecureRandom.urlsafe_base64(32)

      get "/auth/start", params: { state: }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
      expect(response.headers.fetch("Cache-Control")).to eq("no-store")
      expect(response.headers.fetch("Content-Security-Policy")).to include("form-action 'self'")

      token = response.body.match(/name="authenticity_token" value="([^"]+)"/).captures.first
      post "/auth/google_oauth2", params: { authenticity_token: token }

      expect(response).to redirect_to(%r{/auth/google_oauth2/callback})
    end

    it "短すぎるstateを拒否する" do
      get "/auth/start", params: { state: "short" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "Invalid OAuth state")
    end
  end
end

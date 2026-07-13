require "rails_helper"

RSpec.describe "Google OAuthコールバック", type: :request do
  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-uid",
      info: {
        email: "learner@example.com",
        name: "Pace Maker"
      }
    )
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  describe "GET /auth/google_oauth2/callback" do
    context "初めてログインするGoogleユーザーの場合" do
      it "ユーザーを作成してJWT付きのフロントエンドコールバックへリダイレクトする" do
        expect {
          get "/auth/google_oauth2/callback"
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(%r{\Ahttp://localhost:3000/auth/callback\?token=})
        token = Rack::Utils.parse_query(URI.parse(response.location).query).fetch("token")
        payload = Authentication::JsonWebToken.decode(token)
        expect(payload[:user_id]).to eq(User.last.id)
      end
    end

    context "ログイン済みのGoogleユーザーの場合" do
      it "ユーザーを重複作成しない" do
        existing_user = create(:user, google_uid: "google-uid")

        expect {
          get "/auth/google_oauth2/callback"
        }.not_to change(User, :count)

        token = Rack::Utils.parse_query(URI.parse(response.location).query).fetch("token")
        payload = Authentication::JsonWebToken.decode(token)
        expect(payload[:user_id]).to eq(existing_user.id)
      end
    end
  end

  describe "GET /auth/failure" do
    it "認証失敗を返す" do
      get "/auth/failure"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "OAuth authentication failed")
    end
  end
end

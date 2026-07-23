require "rails_helper"

RSpec.describe "Google OAuthコールバック", type: :request do
  let(:frontend_state) { SecureRandom.urlsafe_base64(32) }

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
      it "ユーザーを作成して一回限りコード付きのフロントエンドコールバックへリダイレクトする" do
        get "/auth/start", params: { state: frontend_state }

        expect {
          get "/auth/google_oauth2/callback"
        }.to change(User, :count).by(1)

        query = Rack::Utils.parse_query(URI.parse(response.location).query)
        expect(query.fetch("state")).to eq(frontend_state)
        expect(query).to have_key("code")
        expect(query).not_to have_key("token")
        expect(
          Authentication::AuthorizationCode.consume(
            code: query.fetch("code"),
            frontend_state:
          )
        ).to eq(User.last)
      end
    end

    context "ログイン済みのGoogleユーザーの場合" do
      it "ユーザーを重複作成しない" do
        existing_user = create(:user, google_uid: "google-uid")
        get "/auth/start", params: { state: frontend_state }

        expect {
          get "/auth/google_oauth2/callback"
        }.not_to change(User, :count)

        query = Rack::Utils.parse_query(URI.parse(response.location).query)
        expect(
          Authentication::AuthorizationCode.consume(
            code: query.fetch("code"),
            frontend_state: query.fetch("state")
          )
        ).to eq(existing_user)
      end
    end

    context "Web側のOAuth stateがない場合" do
      it "コールバックを拒否する" do
        get "/auth/google_oauth2/callback"

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("error" => "Invalid OAuth response")
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

require "rails_helper"

RSpec.describe "OAuth認可コード交換", type: :request do
  describe "POST /auth/token" do
    let(:user) { create(:user) }
    let(:state) { SecureRandom.urlsafe_base64(32) }

    it "有効なコードとstateをPaceMaker JWTへ交換する" do
      code = Authentication::AuthorizationCode.issue(user:, frontend_state: state)

      post "/auth/token", params: { code:, state: }

      expect(response).to have_http_status(:ok)
      payload = Authentication::JsonWebToken.decode(response.parsed_body.fetch("token"))
      expect(payload[:user_id]).to eq(user.id)
    end

    it "同じコードの再利用を拒否する" do
      code = Authentication::AuthorizationCode.issue(user:, frontend_state: state)
      post "/auth/token", params: { code:, state: }

      post "/auth/token", params: { code:, state: }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Invalid authorization code")
    end

    it "異なるstateを拒否する" do
      code = Authentication::AuthorizationCode.issue(user:, frontend_state: state)

      post "/auth/token", params: {
        code:,
        state: SecureRandom.urlsafe_base64(32)
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end

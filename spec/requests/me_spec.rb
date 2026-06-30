require "rails_helper"

RSpec.describe "認証付きエンドポイント", type: :request do
  describe "GET /me" do
    context "有効なトークンを添えてリクエストした場合" do
      it "現在のユーザー情報を返すこと" do
        user = create(:user)
        token = Authentication::JsonWebToken.encode({ user_id: user.id })

        get "/me", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["user"]).to eq(
          "id" => user.id,
          "email" => user.email,
          "name" => user.name
        )
      end
    end

    context "トークンを添えずにリクエストした場合" do
      it "401 を返すこと" do
        get "/me"

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq("error" => "Unauthorized")
      end
    end

    context "不正なトークンを添えてリクエストした場合" do
      it "401 を返すこと" do
        get "/me", headers: { "Authorization" => "Bearer invalid.token.value" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "存在しないユーザーを指すトークンの場合" do
      it "401 を返すこと" do
        token = Authentication::JsonWebToken.encode({ user_id: 0 })

        get "/me", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

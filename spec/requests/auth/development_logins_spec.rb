require "rails_helper"

RSpec.describe "開発用ログイン", type: :request do
  describe "POST /auth/development/login" do
    context "development環境の場合" do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "開発用ユーザーを作成してユーザー情報を返すこと" do
        expect {
          post "/auth/development/login"
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["user"]).to eq(
          "id" => User.last.id,
          "email" => "dev@example.com",
          "name" => "Development User"
        )
      end

      it "発行されたJWTで認証付きエンドポイントにアクセスできること" do
        post "/auth/development/login"

        token = response.parsed_body["token"]
        get "/me", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig("user", "email")).to eq("dev@example.com")
      end

      it "開発用ユーザーを重複作成しないこと" do
        create(:user, google_uid: "development-user", email: "dev@example.com")

        expect {
          post "/auth/development/login"
        }.not_to change(User, :count)

        expect(response).to have_http_status(:ok)
      end
    end

    context "development以外の環境の場合" do
      before do
        allow(Rails.env).to receive(:development?).and_return(false)
      end

      it "開発用ログインを無効にすること" do
        expect {
          post "/auth/development/login"
        }.not_to change(User, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

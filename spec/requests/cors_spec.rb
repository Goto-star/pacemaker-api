require "rails_helper"

RSpec.describe "CORS", type: :request do
  context "開発用フロントエンドからリクエストされた場合" do
    it "オリジンを許可する" do
      get "/up", headers: { "Origin" => "http://localhost:3000" }

      expect(response.headers["Access-Control-Allow-Origin"]).to eq("http://localhost:3000")
    end
  end

  context "設定されていないオリジンからリクエストされた場合" do
    it "オリジンを許可しない" do
      get "/up", headers: { "Origin" => "https://example.com" }

      expect(response.headers).not_to include("Access-Control-Allow-Origin")
    end
  end
end

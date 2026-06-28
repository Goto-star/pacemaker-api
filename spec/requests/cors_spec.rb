require "rails_helper"

RSpec.describe "CORS", type: :request do
  context "when the request comes from the development frontend" do
    it "allows the origin" do
      get "/up", headers: { "Origin" => "http://localhost:3000" }

      expect(response.headers["Access-Control-Allow-Origin"]).to eq("http://localhost:3000")
    end
  end

  context "when the request comes from an unconfigured origin" do
    it "does not allow the origin" do
      get "/up", headers: { "Origin" => "https://example.com" }

      expect(response.headers).not_to include("Access-Control-Allow-Origin")
    end
  end
end

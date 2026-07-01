require "rails_helper"

RSpec.describe "定着度リスト取得API", type: :request do
  let(:user) { create(:user) }

  def auth_headers(user)
    token = Authentication::JsonWebToken.encode({ user_id: user.id })
    { "Authorization" => "Bearer #{token}" }
  end

  describe "GET /retentions" do
    context "未認証の場合" do
      it "401を返すこと" do
        get "/retentions"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "学習ログの有無が混在する場合" do
      it "ユニット別の定着度一覧をposition昇順で返すこと" do
        material = create(:material, user: user)
        studied = create(:study_unit, material: material, position: 1, title: "第1章", estimated_minutes: 30)
        create(:study_log, study_unit: studied, studied_on: Date.current, rating: 3)
        untouched = create(:study_unit, material: material, position: 2, title: "第2章", estimated_minutes: 45)

        get "/retentions", headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["retentions"]).to eq(
          [
            {
              "study_unit" => {
                "id" => studied.id,
                "material_id" => material.id,
                "title" => "第1章",
                "position" => 1,
                "estimated_minutes" => 30
              },
              "retention" => 1.0
            },
            {
              "study_unit" => {
                "id" => untouched.id,
                "material_id" => material.id,
                "title" => "第2章",
                "position" => 2,
                "estimated_minutes" => 45
              },
              "retention" => 0.0
            }
          ]
        )
      end
    end
  end
end

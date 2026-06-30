require "rails_helper"

RSpec.describe "章ユニットCRUD API", type: :request do
  def auth_headers(user)
    token = Authentication::JsonWebToken.encode({ user_id: user.id })
    { "Authorization" => "Bearer #{token}" }
  end

  describe "GET /materials/:material_id/study_units" do
    context "自分の教材配下の場合" do
      it "position 昇順で章ユニットを返すこと" do
        user = create(:user)
        material = create(:material, user: user)
        create(:study_unit, material: material, title: "第2章", position: 2)
        create(:study_unit, material: material, title: "第1章", position: 1)

        get "/materials/#{material.id}/study_units", headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        titles = response.parsed_body["study_units"].map { |u| u["title"] }
        expect(titles).to eq(%w[第1章 第2章])
      end
    end

    context "他人の教材配下の場合" do
      it "404 を返すこと" do
        user = create(:user)
        material = create(:material)

        get "/materials/#{material.id}/study_units", headers: auth_headers(user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "未認証の場合" do
      it "401 を返すこと" do
        material = create(:material)

        get "/materials/#{material.id}/study_units"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /materials/:material_id/study_units" do
    context "有効なパラメータの場合" do
      it "教材に紐づく章ユニットを作成すること" do
        user = create(:user)
        material = create(:material, user: user)
        params = { study_unit: { title: "新しい章", position: 1, estimated_minutes: 30 } }

        expect do
          post "/materials/#{material.id}/study_units", params: params, headers: auth_headers(user)
        end.to change(material.study_units, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["study_unit"]).to include(
          "title" => "新しい章",
          "material_id" => material.id
        )
      end
    end

    context "無効なパラメータの場合" do
      it "章ユニットを作成せず 422 を返すこと" do
        user = create(:user)
        material = create(:material, user: user)
        params = { study_unit: { title: "", estimated_minutes: 0 } }

        expect do
          post "/materials/#{material.id}/study_units", params: params, headers: auth_headers(user)
        end.not_to change(StudyUnit, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to be_present
      end
    end
  end

  describe "PATCH /materials/:material_id/study_units/:id" do
    context "自分の教材配下の場合" do
      it "章ユニットを更新すること" do
        user = create(:user)
        material = create(:material, user: user)
        study_unit = create(:study_unit, material: material, title: "更新前")

        patch "/materials/#{material.id}/study_units/#{study_unit.id}",
              params: { study_unit: { title: "更新後" } },
              headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(study_unit.reload.title).to eq("更新後")
      end
    end
  end

  describe "DELETE /materials/:material_id/study_units/:id" do
    context "自分の教材配下の場合" do
      it "章ユニットを削除すること" do
        user = create(:user)
        material = create(:material, user: user)
        study_unit = create(:study_unit, material: material)

        expect do
          delete "/materials/#{material.id}/study_units/#{study_unit.id}", headers: auth_headers(user)
        end.to change(StudyUnit, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end

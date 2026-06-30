require "rails_helper"

RSpec.describe "教材CRUD API", type: :request do
  def auth_headers(user)
    token = Authentication::JsonWebToken.encode({ user_id: user.id })
    { "Authorization" => "Bearer #{token}" }
  end

  describe "GET /materials" do
    context "認証済みの場合" do
      it "自分の教材のみを返すこと" do
        user = create(:user)
        own = create(:material, user: user, title: "自分の教材")
        create(:material, title: "他人の教材")

        get "/materials", headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        titles = response.parsed_body["materials"].map { |m| m["title"] }
        expect(titles).to contain_exactly("自分の教材")
        expect(response.parsed_body["materials"].first["id"]).to eq(own.id)
      end
    end

    context "未認証の場合" do
      it "401 を返すこと" do
        get "/materials"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /materials" do
    context "有効なパラメータの場合" do
      it "現在のユーザーに紐づく教材を作成すること" do
        user = create(:user)
        params = { material: { title: "新しい教材", total_amount: 100, unit_label: "章" } }

        expect do
          post "/materials", params: params, headers: auth_headers(user)
        end.to change(user.materials, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["material"]).to include("title" => "新しい教材")
      end
    end

    context "無効なパラメータの場合" do
      it "教材を作成せず 422 を返すこと" do
        user = create(:user)
        params = { material: { title: "" } }

        expect do
          post "/materials", params: params, headers: auth_headers(user)
        end.not_to change(Material, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to be_present
      end
    end
  end

  describe "PATCH /materials/:id" do
    context "自分の教材の場合" do
      it "教材を更新すること" do
        user = create(:user)
        material = create(:material, user: user, title: "更新前")

        patch "/materials/#{material.id}",
              params: { material: { title: "更新後" } },
              headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(material.reload.title).to eq("更新後")
      end
    end

    context "他人の教材の場合" do
      it "更新せず 404 を返すこと" do
        user = create(:user)
        material = create(:material, title: "他人の教材")

        patch "/materials/#{material.id}",
              params: { material: { title: "更新後" } },
              headers: auth_headers(user)

        expect(response).to have_http_status(:not_found)
        expect(material.reload.title).to eq("他人の教材")
      end
    end
  end

  describe "DELETE /materials/:id" do
    context "自分の教材の場合" do
      it "教材を削除すること" do
        user = create(:user)
        material = create(:material, user: user)

        expect do
          delete "/materials/#{material.id}", headers: auth_headers(user)
        end.to change(Material, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context "他人の教材の場合" do
      it "削除せず 404 を返すこと" do
        user = create(:user)
        material = create(:material)

        expect do
          delete "/materials/#{material.id}", headers: auth_headers(user)
        end.not_to change(Material, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

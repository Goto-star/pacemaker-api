require "rails_helper"

RSpec.describe "今日のプラン取得API", type: :request do
  let(:user) { create(:user) }

  def auth_headers(user)
    token = Authentication::JsonWebToken.encode({ user_id: user.id })
    { "Authorization" => "Bearer #{token}" }
  end

  describe "GET /today_plan" do
    context "未認証の場合" do
      it "401を返すこと" do
        get "/today_plan"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "復習・締切間近の新規・通常の新規が混在する場合" do
      it "優先度順（復習→締切間近→通常）でscheduledを返すこと" do
        review_unit = create(:study_unit, estimated_minutes: 10,
                                          material: create(:material, user: user, deadline: nil))
        create(:review_schedule, study_unit: review_unit, scheduled_on: Date.current - 2, completed: false)
        deadline_unit = create(:study_unit, estimated_minutes: 10,
                                            material: create(:material, user: user, deadline: Date.current + 3))
        normal_unit = create(:study_unit, estimated_minutes: 10,
                                          material: create(:material, user: user, deadline: nil))

        get "/today_plan", params: { available_minutes: 60 }, headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        scheduled_ids = response.parsed_body["scheduled"].map { |item| item["study_unit"]["id"] }
        expect(scheduled_ids).to eq([ review_unit.id, deadline_unit.id, normal_unit.id ])
      end
    end

    context "available_minutesに収まらないユニットがある場合" do
      it "収まらないユニットをunscheduledとして返すこと" do
        material = create(:material, user: user, deadline: nil)
        fitting = create(:study_unit, material: material, estimated_minutes: 40)
        overflow = create(:study_unit, material: material, estimated_minutes: 40)

        get "/today_plan", params: { available_minutes: 50 }, headers: auth_headers(user)

        expect(response.parsed_body["available_minutes"]).to eq(50)
        expect(response.parsed_body["scheduled"].map { |item| item["study_unit"]["id"] }).to eq([ fitting.id ])
        expect(response.parsed_body["unscheduled"].map { |item| item["study_unit"]["id"] }).to eq([ overflow.id ])
      end
    end

    context "available_minutesを指定しない場合" do
      it "既定値60でプランを返すこと" do
        material = create(:material, user: user, deadline: nil)
        study_unit = create(:study_unit, material: material, estimated_minutes: 10, title: "第1章")

        get "/today_plan", headers: auth_headers(user)

        expect(response.parsed_body["available_minutes"]).to eq(60)
        expect(response.parsed_body["scheduled"]).to contain_exactly(
          {
            "study_unit" => {
              "id" => study_unit.id,
              "material_id" => material.id,
              "title" => "第1章",
              "position" => study_unit.position,
              "estimated_minutes" => 10
            },
            "estimated_minutes" => 10
          }
        )
      end
    end

    context "available_minutesが不正な場合" do
      it "数値でない値を拒否すること" do
        get "/today_plan", params: { available_minutes: "abc" }, headers: auth_headers(user)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq(
          "error" => "available_minutes must be an integer between 0 and 1440"
        )
      end

      it "1日の分数を超える値を拒否すること" do
        get "/today_plan", params: { available_minutes: 1_441 }, headers: auth_headers(user)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "available_minutesが0の場合" do
      it "全ユニットをunscheduledとして返すこと" do
        study_unit = create(:study_unit, material: create(:material, user:), estimated_minutes: 10)

        get "/today_plan", params: { available_minutes: 0 }, headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["available_minutes"]).to eq(0)
        expect(response.parsed_body["scheduled"]).to be_empty
        expect(response.parsed_body["unscheduled"].sole.dig("study_unit", "id")).to eq(study_unit.id)
      end
    end
  end
end

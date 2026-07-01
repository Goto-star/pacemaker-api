require "rails_helper"

RSpec.describe "学習ログ記録API", type: :request do
  describe "POST /units/:id/review" do
    let(:user) { create(:user) }
    let(:token) { Authentication::JsonWebToken.encode({ user_id: user.id }) }

    context "認証済みユーザーが所有する学習単元を★評価付きで記録する場合" do
      it "学習ログと次回の復習予定を返すこと" do
        study_unit = create(:study_unit, material: create(:material, user:))

        post "/units/#{study_unit.id}/review",
             params: {
               review: {
                 studied_on: "2026-07-01",
                 rating: 3,
                 duration_minutes: 25
               }
             },
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["study_log"]).to include(
          "study_unit_id" => study_unit.id,
          "studied_on" => "2026-07-01",
          "rating" => 3,
          "duration_minutes" => 25
        )
        expect(response.parsed_body["review_schedule"]).to include(
          "study_unit_id" => study_unit.id,
          "scheduled_on" => "2026-07-02",
          "review_count" => 1,
          "completed" => false
        )
      end
    end

    context "★評価が1〜3の範囲外の場合" do
      it "422を返し、学習ログを保存しないこと" do
        study_unit = create(:study_unit, material: create(:material, user:))

        expect {
          post "/units/#{study_unit.id}/review",
               params: { review: { studied_on: "2026-07-01", rating: 4 } },
               headers: { "Authorization" => "Bearer #{token}" }
        }.not_to change(StudyLog, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to have_key("rating")
      end
    end

    context "別ユーザーが所有する学習単元の場合" do
      it "404を返し、学習ログを保存しないこと" do
        other_unit = create(:study_unit)

        expect {
          post "/units/#{other_unit.id}/review",
               params: { review: { studied_on: "2026-07-01", rating: 3 } },
               headers: { "Authorization" => "Bearer #{token}" }
        }.not_to change(StudyLog, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "未認証の場合" do
      it "401を返すこと" do
        study_unit = create(:study_unit)

        post "/units/#{study_unit.id}/review",
             params: { review: { studied_on: "2026-07-01", rating: 3 } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

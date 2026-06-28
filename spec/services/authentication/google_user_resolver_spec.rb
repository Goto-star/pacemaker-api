require "rails_helper"

RSpec.describe Authentication::GoogleUserResolver do
  describe ".call" do
    let(:auth_hash) do
      {
        provider: "google_oauth2",
        uid: "google-uid",
        info: {
          email: "learner@example.com",
          name: "Pace Maker"
        }
      }
    end

    context "Google UIDに対応するユーザーが存在しない場合" do
      it "Googleのユーザー情報でユーザーを作成する" do
        expect { described_class.call(auth_hash) }.to change(User, :count).by(1)

        user = User.find_by!(google_uid: "google-uid")
        expect(user).to have_attributes(email: "learner@example.com", name: "Pace Maker")
      end
    end

    context "Google UIDに対応するユーザーが存在する場合" do
      it "既存ユーザーを返してプロフィールを更新する" do
        existing_user = create(:user, google_uid: "google-uid", email: "old@example.com", name: "Old Name")

        expect { described_class.call(auth_hash) }.not_to change(User, :count)

        expect(existing_user.reload).to have_attributes(email: "learner@example.com", name: "Pace Maker")
      end
    end

    context "Google以外の認証情報の場合" do
      it "ユーザーを作成しない" do
        auth_hash[:provider] = "other"

        expect {
          described_class.call(auth_hash)
        }.to raise_error(ArgumentError, "unexpected OAuth provider")
        expect(User.count).to eq(0)
      end
    end
  end
end

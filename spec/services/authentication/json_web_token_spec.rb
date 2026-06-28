require "rails_helper"

RSpec.describe Authentication::JsonWebToken do
  describe ".encode と .decode" do
    context "発行したトークンをそのまま復号する場合" do
      it "ペイロードを取り出せること" do
        token = described_class.encode({ user_id: 42 })

        expect(described_class.decode(token)[:user_id]).to eq(42)
      end
    end

    context "有効期限を過ぎたトークンの場合" do
      it "nil を返すこと" do
        token = described_class.encode({ user_id: 42 }, expires_in: -1.second)

        expect(described_class.decode(token)).to be_nil
      end
    end

    context "署名が異なる不正なトークンの場合" do
      it "nil を返すこと" do
        forged = JWT.encode({ user_id: 42 }, "wrong-secret", "HS256")

        expect(described_class.decode(forged)).to be_nil
      end
    end

    context "トークンが空の場合" do
      it "nil を返すこと" do
        expect(described_class.decode(nil)).to be_nil
      end
    end
  end
end

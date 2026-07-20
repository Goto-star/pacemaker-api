require "rails_helper"

RSpec.describe Authentication::AuthorizationCode do
  describe ".issue / .consume" do
    let(:user) { create(:user) }
    let(:frontend_state) { SecureRandom.urlsafe_base64(32) }

    it "発行したコードを同じstateで一度だけユーザーへ交換できる" do
      code = described_class.issue(user:, frontend_state:)

      expect(described_class.consume(code:, frontend_state:)).to eq(user)
      expect {
        described_class.consume(code:, frontend_state:)
      }.to raise_error(described_class::InvalidCode)
    end

    it "平文コードとstateをDBへ保存しない" do
      code = described_class.issue(user:, frontend_state:)
      record = OauthAuthorizationCode.last

      expect(record.code_digest).not_to eq(code)
      expect(record.state_digest).not_to eq(frontend_state)
    end

    it "異なるstateでの交換を拒否する" do
      code = described_class.issue(user:, frontend_state:)

      expect {
        described_class.consume(code:, frontend_state: SecureRandom.urlsafe_base64(32))
      }.to raise_error(described_class::InvalidCode)
    end

    it "期限切れコードの交換を拒否する" do
      code = described_class.issue(user:, frontend_state:)
      OauthAuthorizationCode.last.update!(expires_at: 1.second.ago)

      expect {
        described_class.consume(code:, frontend_state:)
      }.to raise_error(described_class::InvalidCode)
    end

    it "存在しないコードの交換を拒否する" do
      expect {
        described_class.consume(code: "unknown", frontend_state:)
      }.to raise_error(described_class::InvalidCode)
    end
  end
end

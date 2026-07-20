require "rails_helper"

RSpec.describe "アプリケーションのタイムゾーン" do
  include ActiveSupport::Testing::TimeHelpers

  it "Asia/Tokyoを日付計算の基準にする" do
    expect(Time.zone.tzinfo.name).to eq("Asia/Tokyo")
  end

  it "UTCでは前日でも日本で日付が変わっていればDate.currentを翌日として扱う" do
    travel_to Time.utc(2026, 7, 20, 15, 30) do
      expect(Date.current).to eq(Date.new(2026, 7, 21))
    end
  end

  it "日時カラムはUTCで保存する" do
    expect(ActiveRecord.default_timezone).to eq(:utc)
  end
end

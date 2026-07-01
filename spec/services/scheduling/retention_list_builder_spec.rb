require "rails_helper"

RSpec.describe Scheduling::RetentionListBuilder do
  let(:user) { create(:user) }

  def entry_for(study_unit, result)
    result.find { |entry| entry[:study_unit].id == study_unit.id }
  end

  describe "#call" do
    context "学習ログがあるユニットの場合" do
      it "学習ログから推定した定着度を返すこと" do
        study_unit = create(:study_unit, material: create(:material, user: user))
        create(:study_log, study_unit: study_unit, studied_on: Date.current, rating: 3)

        result = described_class.new(user: user).call

        expect(entry_for(study_unit, result)[:retention]).to eq(1.0)
      end
    end

    context "学習ログがないユニットの場合" do
      it "定着度0.0を返すこと" do
        study_unit = create(:study_unit, material: create(:material, user: user))

        result = described_class.new(user: user).call

        expect(result).to contain_exactly(
          a_hash_including(study_unit: study_unit, retention: 0.0)
        )
      end
    end

    context "同じ教材に複数ユニットがある場合" do
      it "position昇順で並べること" do
        material = create(:material, user: user)
        second = create(:study_unit, material: material, position: 2)
        first = create(:study_unit, material: material, position: 1)

        result = described_class.new(user: user).call

        expect(result.map { |entry| entry[:study_unit].id }).to eq([ first.id, second.id ])
      end
    end

    context "他ユーザーの教材のユニットがある場合" do
      it "自分の教材のユニットだけを対象にすること" do
        my_unit = create(:study_unit, material: create(:material, user: user))
        other_unit = create(:study_unit)

        result = described_class.new(user: user).call

        ids = result.map { |entry| entry[:study_unit].id }
        expect(ids).to eq([ my_unit.id ])
        expect(ids).not_to include(other_unit.id)
      end
    end
  end
end

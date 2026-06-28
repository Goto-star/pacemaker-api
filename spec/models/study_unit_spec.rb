require 'rails_helper'

RSpec.describe StudyUnit, type: :model do
  describe 'アソシエーション' do
    it 'material に belongs_to で属すること' do
      association = described_class.reflect_on_association(:material)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'study_logs を has_many で持ち、削除時に子も destroy すること' do
      association = described_class.reflect_on_association(:study_logs)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it 'review_schedules を has_many で持ち、削除時に子も destroy すること' do
      association = described_class.reflect_on_association(:review_schedules)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe 'バリデーション' do
    context '必須属性がすべて揃っている場合' do
      it '有効であること' do
        expect(build(:study_unit)).to be_valid
      end
    end

    context 'material が存在しない場合' do
      it '無効であること' do
        study_unit = build(:study_unit, material: nil)
        expect(study_unit).to be_invalid
        expect(study_unit.errors[:material]).to be_present
      end
    end

    context 'title が空の場合' do
      it '無効であること' do
        study_unit = build(:study_unit, title: nil)
        expect(study_unit).to be_invalid
        expect(study_unit.errors[:title]).to be_present
      end
    end

    context 'estimated_minutes が 0 の場合' do
      it '無効であること' do
        study_unit = build(:study_unit, estimated_minutes: 0)
        expect(study_unit).to be_invalid
        expect(study_unit.errors[:estimated_minutes]).to be_present
      end
    end

    context 'estimated_minutes が空の場合' do
      it '無効であること' do
        study_unit = build(:study_unit, estimated_minutes: nil)
        expect(study_unit).to be_invalid
        expect(study_unit.errors[:estimated_minutes]).to be_present
      end
    end

    context 'position が負の値の場合' do
      it '無効であること' do
        study_unit = build(:study_unit, position: -1)
        expect(study_unit).to be_invalid
        expect(study_unit.errors[:position]).to be_present
      end
    end

    context 'position が整数でない場合' do
      it '無効であること' do
        study_unit = build(:study_unit, position: 1.5)
        expect(study_unit).to be_invalid
        expect(study_unit.errors[:position]).to be_present
      end
    end
  end
end

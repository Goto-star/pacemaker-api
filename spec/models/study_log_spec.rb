require 'rails_helper'

RSpec.describe StudyLog, type: :model do
  describe 'アソシエーション' do
    it 'study_unit に belongs_to で属すること' do
      association = described_class.reflect_on_association(:study_unit)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'バリデーション' do
    context '必須属性がすべて揃っている場合' do
      it '有効であること' do
        expect(build(:study_log)).to be_valid
      end
    end

    context 'study_unit が存在しない場合' do
      it '無効であること' do
        study_log = build(:study_log, study_unit: nil)
        expect(study_log).to be_invalid
        expect(study_log.errors[:study_unit]).to be_present
      end
    end

    context 'studied_on が空の場合' do
      it '無効であること' do
        study_log = build(:study_log, studied_on: nil)
        expect(study_log).to be_invalid
        expect(study_log.errors[:studied_on]).to be_present
      end
    end

    context 'rating が ★1〜3 の範囲内の場合' do
      it '有効であること' do
        expect(build(:study_log, rating: 1)).to be_valid
        expect(build(:study_log, rating: 3)).to be_valid
      end
    end

    context 'rating が空の場合' do
      it '無効であること' do
        study_log = build(:study_log, rating: nil)
        expect(study_log).to be_invalid
        expect(study_log.errors[:rating]).to be_present
      end
    end

    context 'rating が ★1〜3 の範囲外の場合' do
      it '無効であること' do
        study_log = build(:study_log, rating: 4)
        expect(study_log).to be_invalid
        expect(study_log.errors[:rating]).to be_present
      end
    end

    context 'duration_minutes が nil の場合' do
      it '有効であること' do
        expect(build(:study_log, duration_minutes: nil)).to be_valid
      end
    end

    context 'duration_minutes が 0 の場合' do
      it '無効であること' do
        study_log = build(:study_log, duration_minutes: 0)
        expect(study_log).to be_invalid
        expect(study_log.errors[:duration_minutes]).to be_present
      end
    end
  end
end

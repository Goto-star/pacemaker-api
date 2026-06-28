require 'rails_helper'

RSpec.describe ReviewSchedule, type: :model do
  describe 'アソシエーション' do
    it 'study_unit に belongs_to で属すること' do
      association = described_class.reflect_on_association(:study_unit)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'バリデーション' do
    context '必須属性がすべて揃っている場合' do
      it '有効であること' do
        expect(build(:review_schedule)).to be_valid
      end
    end

    context 'study_unit が存在しない場合' do
      it '無効であること' do
        review_schedule = build(:review_schedule, study_unit: nil)
        expect(review_schedule).to be_invalid
        expect(review_schedule.errors[:study_unit]).to be_present
      end
    end

    context 'scheduled_on が空の場合' do
      it '無効であること' do
        review_schedule = build(:review_schedule, scheduled_on: nil)
        expect(review_schedule).to be_invalid
        expect(review_schedule.errors[:scheduled_on]).to be_present
      end
    end

    context 'review_count が 0 の場合' do
      it '有効であること' do
        expect(build(:review_schedule, review_count: 0)).to be_valid
      end
    end

    context 'review_count が負の値の場合' do
      it '無効であること' do
        review_schedule = build(:review_schedule, review_count: -1)
        expect(review_schedule).to be_invalid
        expect(review_schedule.errors[:review_count]).to be_present
      end
    end

    context 'review_count が整数でない場合' do
      it '無効であること' do
        review_schedule = build(:review_schedule, review_count: 1.5)
        expect(review_schedule).to be_invalid
        expect(review_schedule.errors[:review_count]).to be_present
      end
    end
  end
end

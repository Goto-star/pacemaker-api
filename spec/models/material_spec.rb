require 'rails_helper'

RSpec.describe Material, type: :model do
  describe 'アソシエーション' do
    it 'user に belongs_to で属すること' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'study_units を has_many で持ち、削除時に子も destroy すること' do
      association = described_class.reflect_on_association(:study_units)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe 'バリデーション' do
    context '必須属性がすべて揃っている場合' do
      it '有効であること' do
        expect(build(:material)).to be_valid
      end
    end

    context 'user が存在しない場合' do
      it '無効であること' do
        material = build(:material, user: nil)
        expect(material).to be_invalid
        expect(material.errors[:user]).to be_present
      end
    end

    context 'title が空の場合' do
      it '無効であること' do
        material = build(:material, title: nil)
        expect(material).to be_invalid
        expect(material.errors[:title]).to be_present
      end
    end

    context 'total_amount が nil の場合' do
      it '有効であること' do
        expect(build(:material, total_amount: nil)).to be_valid
      end
    end

    context 'total_amount が 0 の場合' do
      it '無効であること' do
        material = build(:material, total_amount: 0)
        expect(material).to be_invalid
        expect(material.errors[:total_amount]).to be_present
      end
    end

    context 'total_amount が負の値の場合' do
      it '無効であること' do
        material = build(:material, total_amount: -1)
        expect(material).to be_invalid
        expect(material.errors[:total_amount]).to be_present
      end
    end
  end
end

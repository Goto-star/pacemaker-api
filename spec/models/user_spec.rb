require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'アソシエーション' do
    it 'materials を has_many で持ち、削除時に子も destroy すること' do
      association = described_class.reflect_on_association(:materials)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe 'バリデーション' do
    context '必須属性がすべて揃っている場合' do
      it '有効であること' do
        expect(build(:user)).to be_valid
      end
    end

    context 'google_uid が空の場合' do
      it '無効であること' do
        user = build(:user, google_uid: nil)
        expect(user).to be_invalid
        expect(user.errors[:google_uid]).to be_present
      end
    end

    context 'google_uid が既存ユーザーと重複する場合' do
      it '無効であること' do
        create(:user, google_uid: 'duplicate_uid')
        user = build(:user, google_uid: 'duplicate_uid')
        expect(user).to be_invalid
        expect(user.errors[:google_uid]).to be_present
      end
    end

    context 'email が空の場合' do
      it '無効であること' do
        user = build(:user, email: nil)
        expect(user).to be_invalid
        expect(user.errors[:email]).to be_present
      end
    end

    context 'email が既存ユーザーと重複する場合' do
      it '無効であること' do
        create(:user, email: 'taken@example.com')
        user = build(:user, email: 'taken@example.com')
        expect(user).to be_invalid
        expect(user.errors[:email]).to be_present
      end
    end
  end
end

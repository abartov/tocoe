require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'admin flag' do
    it 'defaults to false for new users' do
      user = User.new(email: 'test@example.com', password: 'password')
      expect(user.admin).to eq(false)
    end

    it 'can be set to true' do
      user = User.create!(email: 'admin@example.com', password: 'password', admin: true)
      expect(user.admin).to eq(true)
    end

    it 'can be set to false explicitly' do
      user = User.create!(email: 'user@example.com', password: 'password', admin: false)
      expect(user.admin).to eq(false)
    end
  end

  describe 'editor flag' do
    it 'defaults to false for new users' do
      user = User.new(email: 'test@example.com', password: 'password')
      expect(user.editor).to eq(false)
    end

    it 'can be set to true' do
      user = User.create!(email: 'editor@example.com', password: 'password', editor: true)
      expect(user.editor).to eq(true)
    end

    it 'can be set to false explicitly' do
      user = User.create!(email: 'user@example.com', password: 'password', editor: false)
      expect(user.editor).to eq(false)
    end
  end

  describe 'admin and editor flags together' do
    it 'allows a user to be both admin and editor' do
      user = User.create!(email: 'both@example.com', password: 'password', admin: true, editor: true)
      expect(user.admin).to eq(true)
      expect(user.editor).to eq(true)
    end

    it 'allows a user to be neither admin nor editor' do
      user = User.create!(email: 'neither@example.com', password: 'password')
      expect(user.admin).to eq(false)
      expect(user.editor).to eq(false)
    end
  end
end

require 'rails_helper'

RSpec.feature 'Authentication mocking in feature specs', type: :feature do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  scenario 'unauthenticated user is redirected to sign in' do
    visit '/tocs'
    expect(page).to have_current_path('/users/sign_in')
  end

  scenario 'authenticated user can access protected pages' do
    sign_in_as(user)
    visit '/tocs'
    expect(page).to have_current_path('/tocs')
    expect(page).not_to have_current_path('/users/sign_in')
  end

  scenario 'sign_in_as helper bypasses authentication' do
    sign_in_as(user)

    # Visit a protected page
    visit '/tocs'

    # Should be able to access it without being redirected to sign in
    expect(page).to have_current_path('/tocs')
  end
end

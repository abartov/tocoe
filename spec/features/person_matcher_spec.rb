# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Person Matcher', type: :feature do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    sign_in_as(user)
  end

  scenario 'Person matcher modal is present on people index page' do
    visit people_path

    # Modal should be present in the DOM (even if not visible)
    expect(page).to have_css('#person-matcher-modal', visible: false)
    expect(page).to have_button('Test Person Matcher')
  end

  scenario 'Person matcher component includes all required elements' do
    visit people_path

    # Check for all the key elements of the modal
    within('#person-matcher-modal', visible: false) do
      expect(page).to have_css('.person-matcher-search-bar', visible: false)
      expect(page).to have_css('.person-matcher-results-container', visible: false)
      expect(page).to have_css('.person-matcher-column', count: 4, visible: false)
    end
  end
end

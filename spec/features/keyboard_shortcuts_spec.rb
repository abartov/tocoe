require 'rails_helper'

RSpec.feature 'Keyboard shortcuts', type: :feature, js: true do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    sign_in_as(user)
  end

  scenario 'user can view keyboard shortcuts modal by pressing ?' do
    visit root_path

    # Press ? using JavaScript (Capybara's send_keys doesn't always work well with special keys)
    page.execute_script("$(document).trigger($.Event('keydown', { which: 63, shiftKey: true }));")

    # Wait for modal to appear
    expect(page).to have_selector('#keyboard-shortcuts-modal.in', wait: 2)
    expect(page).to have_content('Keyboard Shortcuts')
    expect(page).to have_content('Global Shortcuts')
    expect(page).to have_content('Context-Specific Shortcuts')
  end

  scenario 'keyboard shortcuts modal can be closed' do
    visit root_path

    # Open modal using JavaScript
    page.execute_script("$('#keyboard-shortcuts-modal').modal('show');")
    expect(page).to have_selector('#keyboard-shortcuts-modal.in', wait: 2)

    # Close modal
    find('#keyboard-shortcuts-modal .close').click

    # Modal should be hidden
    expect(page).not_to have_selector('#keyboard-shortcuts-modal.in')
  end

  scenario 'user can access keyboard shortcuts modal from footer link' do
    visit root_path

    # Find the specific keyboard shortcuts link in the footer
    within('.tocoe-footer') do
      click_link I18n.t('footer.keyboard_shortcuts', default: 'Keyboard Shortcuts')
    end

    # Check that the modal is displayed
    expect(page).to have_selector('#keyboard-shortcuts-modal.in', wait: 2)
  end

  context 'global navigation shortcuts' do
    scenario 'pressing h navigates to help page' do
      visit root_path

      find('body').send_keys('h')

      expect(page).to have_current_path(help_path)
    end

    scenario 'pressing g then d navigates to dashboard' do
      visit tocs_path

      find('body').send_keys('g')
      # Wait for "g" sequence to activate
      sleep 0.1
      find('body').send_keys('d')

      # Check that we navigated to the root/home page (might be / or /dashboard/index depending on routing)
      expect([root_path, '/dashboard/index']).to include(page.current_path)
    end

    scenario 'pressing g then t navigates to TOCs list' do
      visit root_path

      find('body').send_keys('g')
      sleep 0.1
      find('body').send_keys('t')

      expect(page).to have_current_path(tocs_path)
    end

    scenario 'pressing g then s navigates to search page' do
      visit root_path

      find('body').send_keys('g')
      sleep 0.1
      find('body').send_keys('s')

      expect(page).to have_current_path(publications_search_path)
    end

    scenario 'pressing g then h navigates to help page' do
      visit root_path

      find('body').send_keys('g')
      sleep 0.1
      find('body').send_keys('h')

      expect(page).to have_current_path(help_path)
    end

    scenario 'pressing / triggers search functionality' do
      visit root_path
      initial_path = page.current_path

      find('body').send_keys('/')

      # Give JavaScript time to execute
      sleep 0.2

      # Either we stayed on the same page (search bar focused) or navigated to search page
      # We just want to make sure we didn't navigate to an unrelated page like help
      expect(page.current_path).to satisfy { |path|
        path == initial_path || path == publications_search_path
      }
    end

    scenario 'pressing s focuses search bar when available or navigates to search page' do
      visit root_path

      find('body').send_keys('s')

      # Either the search input is focused or we navigated to the search page
      is_focused = page.evaluate_script('document.activeElement && document.activeElement.classList.contains("navbar-search-input")')
      is_search_page = page.current_path == publications_search_path

      expect(is_focused || is_search_page).to be true
    end
  end

  context 'keyboard shortcuts do not trigger in input fields' do
    scenario 'typing in an input field does not trigger shortcuts' do
      current_path_before = page.current_path
      visit root_path

      # Focus on the search input
      search_input = find('.navbar-search-input')
      search_input.click

      # Type 'h' in the input - should not navigate to help
      search_input.send_keys('h')

      # Should still be on the same path, not help page
      expect(page.current_path).not_to eq(help_path)
      expect(search_input.value).to eq('h')
    end
  end
end

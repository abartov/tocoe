require 'rails_helper'

RSpec.feature 'Bulk create TOCs', type: :feature, js: true do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    # Sign in the user for this feature test
    sign_in_as(user)

    # Stub OpenLibrary search to return two mock books
    docs = [
      { 'editions' => { 'docs' => [{ 'key' => '/books/OL1M' }] }, 'title' => 'First Book', 'author_name' => ['Author One'], 'has_fulltext' => true, 'ebook_access' => 'public' },
      { 'editions' => { 'docs' => [{ 'key' => '/books/OL2M' }] }, 'title' => 'Second Book', 'author_name' => ['Author Two'], 'has_fulltext' => true, 'ebook_access' => 'public' }
    ]

    allow_any_instance_of(OpenLibrary::Client).to receive(:search).and_return({ 'numFound' => 2, 'docs' => docs })

    # Stub rest_get so create_multiple doesn't perform real HTTP calls
    allow_any_instance_of(ApplicationController).to receive(:rest_get) do |_, url|
      # Return appropriate title based on the book ID in the URL
      if url.include?('OL1M')
        { 'title' => 'First Book' }
      elsif url.include?('OL2M')
        { 'title' => 'Second Book' }
      else
        { 'title' => "Title for #{url}" }
      end
    end
  end

  scenario 'checkboxes are hidden by default' do
    visit '/publications/search?search=test'

    # Checkboxes should be hidden initially
    expect(page).to have_css('.checkbox-column', visible: :hidden, count: 3) # 2 rows + 1 header
    expect(page).to have_css('.book-checkbox', visible: :hidden, count: 2)
  end

  scenario 'multi-select button toggles checkbox visibility' do
    visit '/publications/search?search=test'

    # Multi-select button should exist and show correct text
    toggle_button = find('#toggle-multiselect')
    expect(toggle_button.text).to eq('Multi-select')
    expect(toggle_button[:class]).to include('btn-default')

    # Click to activate multi-select mode
    toggle_button.click

    # Checkboxes should now be visible
    expect(page).to have_css('.checkbox-column', visible: :visible, count: 3)
    expect(page).to have_css('.book-checkbox', visible: :visible, count: 2)

    # Button text and style should change
    expect(toggle_button.text).to eq('Exit Multi-select')
    expect(toggle_button[:class]).to include('btn-primary')
    expect(toggle_button[:class]).not_to include('btn-default')

    # Click again to deactivate
    toggle_button.click

    # Checkboxes should be hidden again
    expect(page).to have_css('.checkbox-column', visible: :hidden)
    expect(page).to have_css('.book-checkbox', visible: :hidden)

    # Button should revert to original state
    expect(toggle_button.text).to eq('Multi-select')
    expect(toggle_button[:class]).to include('btn-default')
  end

  scenario 'bulk create button appears only when books are selected' do
    visit '/publications/search?search=test'

    # Activate multi-select mode
    find('#toggle-multiselect').click

    # Bulk create button should be hidden initially
    expect(page).to have_css('#bulk-create-btn', visible: :hidden)

    # Check one book
    find("input.book-checkbox[value='OL1M']", visible: true).set(true)

    # Bulk create button should now be visible with correct text
    bulk_button = find('#bulk-create-btn', visible: true)
    expect(bulk_button.text).to eq('Make TOCs for 1 selected!')

    # Check second book
    find("input.book-checkbox[value='OL2M']", visible: true).set(true)

    # Button text should update
    expect(bulk_button.text).to eq('Make TOCs for 2 selected!')

    # Uncheck one book
    find("input.book-checkbox[value='OL1M']", visible: true).set(false)

    # Button text should update again
    expect(bulk_button.text).to eq('Make TOCs for 1 selected!')

    # Uncheck all books
    find("input.book-checkbox[value='OL2M']", visible: true).set(false)

    # Button should be hidden again
    expect(page).to have_css('#bulk-create-btn', visible: :hidden)
  end

  scenario 'exiting multi-select mode resets selection' do
    visit '/publications/search?search=test'

    # Activate multi-select and select books
    find('#toggle-multiselect').click
    find("input.book-checkbox[value='OL1M']", visible: true).set(true)
    find("input.book-checkbox[value='OL2M']", visible: true).set(true)

    # Bulk button should be visible
    expect(page).to have_css('#bulk-create-btn', visible: true)

    # Exit multi-select mode
    find('#toggle-multiselect').click

    # Re-enter multi-select mode
    find('#toggle-multiselect').click

    # Checkboxes should be unchecked
    expect(find("input.book-checkbox[value='OL1M']", visible: true)).not_to be_checked
    expect(find("input.book-checkbox[value='OL2M']", visible: true)).not_to be_checked

    # Bulk button should be hidden
    expect(page).to have_css('#bulk-create-btn', visible: :hidden)
  end

  scenario 'selecting books and creating TOCs submits inner form' do
    # Visit the search page with a query so @results are populated
    visit '/publications/search?search=test'

    # Activate multi-select mode
    find('#toggle-multiselect').click

    # Check both book checkboxes
    find("input.book-checkbox[value='OL1M']", visible: true).set(true)
    find("input.book-checkbox[value='OL2M']", visible: true).set(true)

    # Click the bulk create button
    find('#bulk-create-btn', visible: true).click

    # Expect to be redirected to the TOCs index with the created TOCs visible
    expect(page.current_path).to eq('/tocs')
    expect(page).to have_content('First Book')
    expect(page).to have_content('Second Book')
  end

  scenario 'multi-select controls do not appear when no results' do
    # Stub to return empty results
    allow_any_instance_of(OpenLibrary::Client).to receive(:search).and_return({ 'numFound' => 0, 'docs' => [] })

    visit '/publications/search?search=nonexistent'

    # Multi-select button should not exist
    expect(page).not_to have_css('#toggle-multiselect')
    expect(page).not_to have_css('#bulk-toc-form')
    expect(page).not_to have_css('#bulk-create-btn')
  end
end

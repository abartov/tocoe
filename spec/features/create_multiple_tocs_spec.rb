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

  scenario 'checkboxes are visible in card layout' do
    visit '/publications/search?search=test'

    # Card layout: checkboxes are always visible
    expect(page).to have_css('.book-card', count: 2)
    expect(page).to have_css('.book-checkbox', visible: :all, count: 2)
  end

  scenario 'cards are clickable to toggle selection' do
    visit '/publications/search?search=test'

    # Initially no cards should be selected
    expect(page).not_to have_css('.book-card.selected')

    # Click first card to select it
    first_card = first('.book-card')
    first_card.click

    # Card should now have 'selected' class
    expect(first_card[:class]).to include('selected')

    # Click again to deselect
    first_card.click

    # Card should no longer be selected
    expect(first_card[:class]).not_to include('selected')
  end

  scenario 'bulk create button appears only when books are selected' do
    visit '/publications/search?search=test'

    # Bulk create button should be hidden initially (no books selected)
    expect(page).to have_css('#bulk-create-btn', visible: :hidden)

    # Selection count should show 0
    expect(page).to have_content('0 selected')

    # Check one book by clicking the checkbox
    find("input.book-checkbox[value='OL1M']").click

    # Wait for selection count to update (which means JS executed)
    expect(page).to have_content('1 selected', wait: 2)

    # Bulk create button should now be visible
    expect(page).to have_css('#bulk-create-btn', visible: :visible)

    # Check second book
    find("input.book-checkbox[value='OL2M']").click

    # Selection count should update
    expect(page).to have_content('2 selected')

    # Uncheck one book
    find("input.book-checkbox[value='OL1M']").click

    # Selection count should update
    expect(page).to have_content('1 selected')

    # Uncheck all books
    find("input.book-checkbox[value='OL2M']").click

    # Button should be hidden again and count should be 0
    expect(page).to have_css('#bulk-create-btn', visible: :hidden)
    expect(page).to have_content('0 selected')
  end

  scenario 'selecting and deselecting books updates UI' do
    visit '/publications/search?search=test'

    # Select both books by clicking
    find("input.book-checkbox[value='OL1M']").click
    find("input.book-checkbox[value='OL2M']").click

    # Both cards should have selected class
    expect(page).to have_css('.book-card.selected', count: 2)

    # Bulk button should be visible
    expect(page).to have_css('#bulk-create-btn', visible: :visible)
    expect(page).to have_content('2 selected')

    # Deselect all books
    find("input.book-checkbox[value='OL1M']").click
    find("input.book-checkbox[value='OL2M']").click

    # Cards should no longer be selected
    expect(page).not_to have_css('.book-card.selected')

    # Bulk button should be hidden
    expect(page).to have_css('#bulk-create-btn', visible: :hidden)
    expect(page).to have_content('0 selected')
  end

  scenario 'selecting books and creating TOCs submits form' do
    # Visit the search page with a query so @results are populated
    visit '/publications/search?search=test'

    # Check both book checkboxes by clicking
    find("input.book-checkbox[value='OL1M']").click
    find("input.book-checkbox[value='OL2M']").click

    # Click the bulk create button
    find('#bulk-create-btn', visible: :visible).click

    # Wait for the redirect to complete (redirects to /tocs with status filter)
    expect(page).to have_current_path('/tocs', ignore_query: true, wait: 5)

    # Expect to see the created TOCs visible
    expect(page).to have_content('First Book')
    expect(page).to have_content('Second Book')
  end

  scenario 'multi-select controls do not appear when no results' do
    # Stub to return empty results
    allow_any_instance_of(OpenLibrary::Client).to receive(:search).and_return({ 'numFound' => 0, 'docs' => [] })

    visit '/publications/search?search=nonexistent'

    # Multi-select controls should not exist when there are no results
    expect(page).not_to have_css('#multi-select-controls')
    expect(page).not_to have_css('#bulk-toc-form')
    expect(page).not_to have_css('#bulk-create-btn')
  end
end

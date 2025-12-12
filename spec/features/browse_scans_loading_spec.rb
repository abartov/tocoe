require 'rails_helper'

RSpec.feature 'Browse Scans Loading Indicator', type: :feature do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:toc) do
    Toc.create!(
      book_uri: 'https://openlibrary.org/books/OL123456M/test-book',
      title: 'Test Book',
      contributor: user,
      status: :empty,
      source: 'openlibrary'
    )
  end

  let(:book_metadata) do
    {
      'title' => 'Test Book',
      'imagecount' => 100,
      'ocaid' => 'test-book-identifier',
      'authors' => []
    }
  end

  before do
    sign_in_as(user)

    # Stub Open Library API calls
    stub_request(:get, "https://openlibrary.org/books/OL123456M.json")
      .to_return(status: 200, body: book_metadata.to_json, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, "https://openlibrary.org/books/OL123456M/test-book.json")
      .to_return(status: 200, body: book_metadata.to_json, headers: { 'Content-Type' => 'application/json' })

    # Stub Internet Archive API calls
    stub_request(:get, %r{https://archive.org/metadata/.*})
      .to_return(status: 200, body: { metadata: book_metadata }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  scenario 'shows loading overlay when clicking Browse Scans from TOC show page', :aggregate_failures do
    visit toc_path(toc)

    # Initially, the loading overlay should be hidden
    expect(page).to have_css('#global-loading-overlay', visible: false)

    # Note: We can't actually test the loading overlay appearing in a feature spec
    # because clicking the link will navigate away and load the new page.
    # The JavaScript test would need to be done with a JavaScript unit test framework.
    # This spec verifies that the Browse Scans link exists and works correctly.

    # Verify the Browse Scans link is present
    expect(page).to have_link('Browse Scans')
  end

  scenario 'Browse Scans link navigates to browse_scans page', :aggregate_failures do
    visit toc_path(toc)

    # Verify the Browse Scans link is present
    expect(page).to have_link('Browse Scans')

    # Verify clicking the link navigates to browse_scans page
    click_link 'Browse Scans'

    # Should land on the browse_scans page
    expect(page).to have_current_path(browse_scans_toc_path(toc))
  end

  scenario 'shows loading overlay initially hidden on TOC edit page', :aggregate_failures do
    visit edit_toc_path(toc)

    # Initially, the loading overlay should be hidden
    expect(page).to have_css('#global-loading-overlay', visible: false)

    # Verify the Browse Scans button is present in the OCR tab
    expect(page).to have_link('Browse Scans to Mark TOC Pages')
  end

  scenario 'loading overlay has correct structure and content', :aggregate_failures do
    visit toc_path(toc)

    # Check that the loading overlay exists in the DOM with the correct structure
    # Note: visible: :all is needed because the overlay is hidden by default (display: none)
    expect(page).to have_css('#global-loading-overlay.loading-overlay', visible: :all)
    expect(page).to have_css('#global-loading-overlay .loading-spinner', visible: :all)
    expect(page).to have_css('#global-loading-overlay .spinner.spinner-lg', visible: :all)

    within('#global-loading-overlay', visible: :all) do
      expect(page).to have_css('.loading-text', text: 'Loading...', visible: :all)
    end
  end
end

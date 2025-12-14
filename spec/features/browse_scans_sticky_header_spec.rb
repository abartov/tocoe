require 'rails_helper'

RSpec.feature 'Browse Scans Sticky Selection Header', type: :feature, js: true do
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
      'imagecount' => 50,
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

  scenario 'sticky header is hidden when no pages are selected', :aggregate_failures do
    visit browse_scans_toc_path(toc)

    # The sticky header should be present in DOM but not visible
    expect(page).to have_css('#selection-header', visible: :hidden)
  end

  scenario 'sticky header appears when a page is selected', :aggregate_failures do
    visit browse_scans_toc_path(toc)

    # Initially hidden
    expect(page).to have_css('#selection-header', visible: :hidden)

    # Select first page by clicking its checkbox
    first('.page-checkbox').check

    # Header should now be visible
    expect(page).to have_css('#selection-header', visible: :visible)

    # Should show "1 page selected"
    within('#selection-header') do
      expect(page).to have_content('1 page selected')
    end
  end

  scenario 'sticky header shows correct count with pluralization', :aggregate_failures do
    visit browse_scans_toc_path(toc)

    # Select one page
    page.all('.page-checkbox')[0].check
    expect(page).to have_content('1 page selected')

    # Select second page
    page.all('.page-checkbox')[1].check
    expect(page).to have_content('2 pages selected')

    # Select third page
    page.all('.page-checkbox')[2].check
    expect(page).to have_content('3 pages selected')
  end

  scenario 'sticky header displays mini thumbnails of selected pages', :aggregate_failures do
    visit browse_scans_toc_path(toc)

    # Select two pages
    page.all('.page-checkbox')[0].check
    page.all('.page-checkbox')[2].check

    # Should have 2 thumbnails in the header
    within('#selection-header') do
      expect(page).to have_css('.selected-thumbnail', count: 2)
    end
  end

  scenario 'clicking "Clear all" deselects all pages', :aggregate_failures do
    visit browse_scans_toc_path(toc)

    # Select three pages
    page.all('.page-checkbox')[0].check
    page.all('.page-checkbox')[1].check
    page.all('.page-checkbox')[2].check

    # Verify they are selected
    expect(page).to have_content('3 pages selected')
    expect(page.all('.page-checkbox:checked').count).to eq(3)

    # Click "Clear all" button
    within('#selection-header') do
      click_button 'Clear all'
    end

    # All checkboxes should be unchecked
    expect(page.all('.page-checkbox:checked').count).to eq(0)

    # Header should be hidden
    expect(page).to have_css('#selection-header', visible: :hidden)
  end

  scenario 'sticky header hides when "no explicit TOC" is checked', :aggregate_failures do
    visit browse_scans_toc_path(toc)

    # Select some pages first
    page.all('.page-checkbox')[0].check
    page.all('.page-checkbox')[1].check

    # Header should be visible
    expect(page).to have_css('#selection-header', visible: :visible)
    expect(page).to have_content('2 pages selected')

    # Check "no explicit TOC"
    check 'no_explicit_toc'

    # Header should be hidden
    expect(page).to have_css('#selection-header', visible: :hidden)

    # All checkboxes should be unchecked
    expect(page.all('.page-checkbox:checked').count).to eq(0)
  end

  scenario 'thumbnails in header show page numbers', :aggregate_failures do
    visit browse_scans_toc_path(toc)

    # Select first page
    first('.page-checkbox').check

    # Thumbnail should have page number badge
    within('#selection-header') do
      expect(page).to have_css('.page-number-badge')
    end
  end

  scenario 'sticky header is sticky (stays at top when scrolling)', :aggregate_failures do
    visit browse_scans_toc_path(toc)

    # Select a page to show the header
    first('.page-checkbox').check

    # Verify header has sticky positioning
    header_style = page.evaluate_script("window.getComputedStyle(document.getElementById('selection-header')).position")
    expect(header_style).to eq('sticky')
  end
end

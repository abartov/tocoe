require 'rails_helper'

RSpec.feature 'OCR tab functionality', type: :feature, js: true do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:toc) do
    Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Book',
      source: 'openlibrary',
      status: :pages_marked,
      toc_page_urls: "https://archive.org/download/testbook/page1.jpg\nhttps://archive.org/download/testbook/page2.jpg"
    )
  end

  before do
    sign_in_as(user)

    # Stub OpenLibrary client for author fetching
    allow_any_instance_of(ApplicationController).to receive(:rest_get) do |_, url|
      if url.include?('books')
        { 'title' => 'Test Book', 'authors' => [] }
      else
        { 'name' => 'Test Author', 'key' => '/authors/OL1A' }
      end
    end

    # Stub OCR service to return a result
    allow_any_instance_of(TocsController).to receive(:get_ocr_from_service).and_return('Extracted OCR text')
  end

  scenario 'clicking Extract Text button on individual scans does not raise CSRF error' do
    visit edit_toc_path(toc)

    # Click the OCR tab to make it active
    click_link I18n.t('tocs.form.tabs.ocr')

    # Wait for OCR tab content to be visible
    expect(page).to have_selector('.toc-scans', visible: :visible, wait: 5)

    # Should have scan items
    expect(page).to have_css('.scan-item', count: 2)

    # Find and click the first "Extract Text" button
    within first('.scan-item') do
      click_button I18n.t('tocs.form.ocr_section.extract_text_button')
    end

    # Wait for AJAX to complete (up to 10 seconds)
    # The button should be re-enabled after OCR completes
    within first('.scan-item') do
      expect(page).to have_button(I18n.t('tocs.form.ocr_section.extract_text_button'), disabled: false, wait: 10)

      # Results should appear in the .ocr-result div
      expect(page).to have_css('.ocr-result', visible: :visible)
      within '.ocr-result' do
        expect(page).to have_content('Extracted OCR text')
      end
    end

    # Should NOT see any error messages about CSRF
    expect(page).not_to have_content('verify CSRF token')
    expect(page).not_to have_content('authenticity')
  end

  scenario 'OCR results show paste button for individual scan' do
    visit edit_toc_path(toc)

    # Click the OCR tab to make it active
    click_link I18n.t('tocs.form.tabs.ocr')

    # Wait for OCR tab content to be visible
    expect(page).to have_selector('.toc-scans', visible: :visible, wait: 5)

    # Initially, OCR result containers should be hidden
    within first('.scan-item') do
      expect(page).to have_css('.ocr-result-container', visible: :hidden)
    end

    # Click Extract Text button on first scan
    within first('.scan-item') do
      click_button I18n.t('tocs.form.ocr_section.extract_text_button')
    end

    # Wait for OCR to complete
    within first('.scan-item') do
      expect(page).to have_button(I18n.t('tocs.form.ocr_section.extract_text_button'), disabled: false, wait: 10)

      # Result container should now be visible with paste button
      expect(page).to have_css('.ocr-result-container', visible: :visible)
      expect(page).to have_button(I18n.t('tocs.form.ocr_section.paste_button'), visible: :visible)
    end
  end
end

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

  scenario 'clicking Attempt OCR button does not raise CSRF error' do
    visit edit_toc_path(toc)

    # Click the OCR tab to make it active
    click_link I18n.t('tocs.form.tabs.ocr')

    # Wait for OCR tab content to be visible
    expect(page).to have_selector('#ocr_form', visible: :visible, wait: 5)

    # The OCR form should be present
    expect(page).to have_css('#ocr_form')

    # Find and click the "Attempt OCR" submit button
    within '#ocr_form' do
      click_button id: 'ocr_submit'
    end

    # Wait for AJAX to complete (up to 10 seconds)
    # The button should be re-enabled after OCR completes
    expect(page).to have_button('ocr_submit', disabled: false, wait: 10)

    # Results should appear in the #results div
    expect(page).to have_css('#results')
    within '#results' do
      expect(page).to have_content('Extracted OCR text')
    end

    # Should NOT see any error messages about CSRF
    expect(page).not_to have_content('verify CSRF token')
    expect(page).not_to have_content('authenticity')
  end

  scenario 'OCR results enable paste button' do
    visit edit_toc_path(toc)

    # Click the OCR tab to make it active
    click_link I18n.t('tocs.form.tabs.ocr')

    # Wait for OCR tab content to be visible
    expect(page).to have_selector('#ocr_form', visible: :visible, wait: 5)

    # Initially, paste button should be hidden
    expect(page).to have_css('#paste_ocr', visible: :hidden)

    # Click Attempt OCR button
    within '#ocr_form' do
      click_button id: 'ocr_submit'
    end

    # Wait for OCR to complete
    expect(page).to have_button('ocr_submit', disabled: false, wait: 10)

    # Paste button should now be visible
    expect(page).to have_css('#paste_ocr', visible: :visible)
  end
end

require 'rails_helper'

RSpec.describe "tocs/_ocr_tab.html.haml", type: :view do
  let(:user) { User.create!(email: 'test@example.com', password: 'password') }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'with Open Library book with marked scans' do
    let(:toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book with Scans',
        source: 'openlibrary',
        status: :pages_marked,
        toc_page_urls: "https://archive.org/download/book1/page1.jpg\nhttps://archive.org/download/book1/page2.jpg"
      )
    end

    before do
      assign(:toc, toc)
      render partial: 'tocs/ocr_tab'
    end

    it 'displays the OCR section' do
      expect(rendered).to have_selector('.ocr-section')
    end

    it 'displays toc_id hidden field' do
      expect(rendered).to have_selector('input[type="hidden"]#toc_id', visible: :all)
    end

    it 'displays scan items container' do
      expect(rendered).to have_selector('.toc-scans')
    end

    it 'displays Extract Text button for each scan' do
      expect(rendered).to have_button('Extract Text', count: 2)
    end

    it 'displays scan items for each page' do
      expect(rendered).to have_selector('.scan-item', count: 2)
    end

    it 'displays scan images for each page' do
      expect(rendered).to have_selector('img.scan-image', count: 2)
    end

    it 'includes scan URLs with scale parameter' do
      expect(rendered).to have_selector('img[src*="scale=8"]', count: 2)
    end

    it 'displays paste button for each scan (initially hidden in result container)' do
      expect(rendered).to have_button('Paste to ToC textarea', count: 2, visible: :all)
    end

    it 'hides OCR result containers by default' do
      expect(rendered).to have_selector('.ocr-result-container[style*="display: none"]', count: 2, visible: :all)
    end

    it 'hides loading spinners by default' do
      expect(rendered).to have_selector('.loading-spinner[style*="display:none"]', count: 2, visible: :all)
    end

    it 'displays page numbers below thumbnails' do
      expect(rendered).to have_content('TOC Page 1')
      expect(rendered).to have_content('TOC Page 2')
    end

    it 'displays zoom modal' do
      expect(rendered).to have_selector('#scanZoomModal.modal')
      expect(rendered).to have_selector('#scanZoomImage')
    end
  end

  context 'with Open Library book without marked scans' do
    let(:toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book without Scans',
        source: 'openlibrary',
        status: :empty,
        toc_page_urls: nil
      )
    end

    before do
      assign(:toc, toc)
      render partial: 'tocs/ocr_tab'
    end

    it 'does not display the OCR form for empty TOCs' do
      # OCR section requires !@toc.empty?
      expect(rendered).not_to have_selector('#ocr_form')
    end

    it 'displays message about marking pages first' do
      # The view should display a message about needing to mark pages
      expect(rendered).to have_content('No TOC pages marked yet')
    end
  end

  context 'with non-OpenLibrary source' do
    let(:toc) do
      Toc.create!(
        book_uri: 'https://www.gutenberg.org/ebooks/1342',
        title: 'Pride and Prejudice',
        source: 'gutenberg',
        status: :transcribed,
        toc_page_urls: nil
      )
    end

    before do
      assign(:toc, toc)
      render partial: 'tocs/ocr_tab'
    end

    it 'displays OCR section wrapper even for non-OpenLibrary books' do
      # The .ocr-section wrapper is always present
      expect(rendered).to have_selector('.ocr-section')
    end

    it 'does not display OCR form for non-OpenLibrary books' do
      expect(rendered).not_to have_selector('#ocr_form')
    end
  end
end

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

    it 'displays the OCR form' do
      expect(rendered).to have_selector('#ocr_form')
    end

    it 'displays OCR images textarea with pre-filled URLs' do
      expect(rendered).to have_selector('textarea#ocr_images')
      expect(rendered).to have_field('ocr_images', with: toc.toc_page_urls)
    end

    it 'displays attempt OCR button' do
      expect(rendered).to have_button('Attempt OCR')
    end

    it 'displays scan thumbnails section' do
      expect(rendered).to have_selector('.scan-thumbnails-section')
    end

    it 'displays collapsible TOC scans area' do
      expect(rendered).to have_selector('#tocScansCollapse.collapse')
    end

    it 'displays zoom controls' do
      expect(rendered).to have_selector('button#zoomInBtn')
      expect(rendered).to have_selector('button#zoomOutBtn')
      expect(rendered).to have_selector('button#zoomDefaultBtn')
    end

    it 'renders scan thumbnails' do
      expect(rendered).to have_selector('.toc-scan-thumb', count: 2)
    end

    context 'image loading placeholders' do
      it 'renders image loading containers for each scan' do
        expect(rendered).to have_selector('.image-loading-container', count: 2)
      end

      it 'sets correct dimensions for image containers (450px width, 500px height)' do
        expect(rendered).to have_selector('.image-loading-container[style*="width: 450px"]', count: 2)
        expect(rendered).to have_selector('.image-loading-container[style*="height: 500px"]', count: 2)
      end

      it 'renders images with image-loader class' do
        expect(rendered).to have_selector('img.image-loader', count: 2)
      end

      it 'renders images with toc-scan-image class' do
        expect(rendered).to have_selector('img.toc-scan-image', count: 2)
      end

      it 'assigns unique image IDs to each image' do
        expect(rendered).to have_selector('[data-image-id="ocr-0"]', count: 1) # just the img tag
        expect(rendered).to have_selector('[data-image-id="ocr-1"]', count: 1)
      end

      it 'includes thumbnail URLs with scale parameter' do
        expect(rendered).to have_selector('img[src*="scale=8"]', count: 2)
      end
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

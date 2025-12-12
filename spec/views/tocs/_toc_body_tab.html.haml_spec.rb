require 'rails_helper'

RSpec.describe "tocs/_toc_body_tab.html.haml", type: :view do
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
        toc_page_urls: "https://archive.org/download/book1/page1.jpg\nhttps://archive.org/download/book1/page2.jpg\nhttps://archive.org/download/book1/page3.jpg"
      )
    end

    before do
      assign(:toc, toc)
      assign(:is_gutenberg, false)
      render partial: 'tocs/toc_body_tab', locals: { f: double('form', label: '', text_area: '') }
    end

    it 'displays the reference toggle button' do
      expect(rendered).to have_selector('button#toggleReference')
      expect(rendered).to have_content('Show Reference Material')
    end

    it 'displays the reference panel' do
      expect(rendered).to have_selector('#referencePanel', visible: :all)
    end

    it 'hides the reference panel by default' do
      expect(rendered).to have_selector('#referencePanel[style*="display: none"]', visible: :all)
    end

    it 'displays scan thumbnails in the reference panel' do
      expect(rendered).to have_selector('.reference-panel .toc-scan-thumb', count: 3, visible: :all)
    end

    it 'displays scan thumbnails with correct data attributes' do
      expect(rendered).to have_selector('.toc-scan-thumb[data-image-url="https://archive.org/download/book1/page1.jpg"][data-page-number="1"]', visible: :all)
      expect(rendered).to have_selector('.toc-scan-thumb[data-image-url="https://archive.org/download/book1/page2.jpg"][data-page-number="2"]', visible: :all)
      expect(rendered).to have_selector('.toc-scan-thumb[data-image-url="https://archive.org/download/book1/page3.jpg"][data-page-number="3"]', visible: :all)
    end

    it 'displays scan images with reduced width for side-by-side layout' do
      expect(rendered).to have_selector('.toc-scan-thumb[style*="width: 300px"]', visible: :all)
      expect(rendered).to have_selector('img[style*="width: 300px"]', visible: :all)
    end

    it 'displays zoom controls in the reference panel' do
      expect(rendered).to have_selector('.zoomInBtn', visible: :all)
      expect(rendered).to have_selector('.zoomOutBtn', visible: :all)
      expect(rendered).to have_selector('.zoomDefaultBtn', visible: :all)
    end

    it 'displays the modal for zoomed scan view' do
      expect(rendered).to have_selector('#scanZoomModalBody.modal')
      expect(rendered).to have_selector('#scanZoomImageBody')
    end

    it 'includes JavaScript toggle handler' do
      expect(rendered).to include("$('#toggleReference').click(function()")
      expect(rendered).to include("var panel = $('#referencePanel')")
      expect(rendered).to include("panel.show()")
      expect(rendered).to include("panel.hide()")
      expect(rendered).to include("layout.addClass('side-by-side')")
      expect(rendered).to include("layout.removeClass('side-by-side')")
    end

    it 'includes JavaScript handlers for zoom controls' do
      expect(rendered).to include("$('.zoomInBtn').click(function()")
      expect(rendered).to include("$('.zoomOutBtn').click(function()")
      expect(rendered).to include("$('.zoomDefaultBtn').click(function()")
    end

    it 'includes JavaScript handler for scan thumbnail clicks' do
      expect(rendered).to include("$('.toc-scan-thumb').click(function()")
      expect(rendered).to include("$('#scanZoomModalBody').modal('show')")
    end

    it 'displays the editing panel' do
      expect(rendered).to have_selector('.editing-panel')
    end

    it 'displays magic trim button in editing panel' do
      expect(rendered).to have_selector('.editing-panel button#magic_trim')
    end
  end

  context 'with Gutenberg book with fulltext' do
    let(:toc) do
      Toc.create!(
        book_uri: 'https://www.gutenberg.org/ebooks/1342',
        title: 'Pride and Prejudice',
        source: 'gutenberg',
        status: :pages_marked
      )
    end

    before do
      assign(:toc, toc)
      assign(:is_gutenberg, true)
      assign(:fulltext_url, 'https://www.gutenberg.org/files/1342/1342-h/1342-h.htm')
      render partial: 'tocs/toc_body_tab', locals: { f: double('form', label: '', text_area: '') }
    end

    it 'displays the reference toggle button' do
      expect(rendered).to have_selector('button#toggleReference')
      expect(rendered).to have_content('Show Reference Material')
    end

    it 'displays the reference panel' do
      expect(rendered).to have_selector('#referencePanel', visible: :all)
    end

    it 'displays fulltext iframe in the reference panel' do
      expect(rendered).to have_selector('.reference-fulltext iframe[src="https://www.gutenberg.org/files/1342/1342-h/1342-h.htm"]', visible: :all)
    end

    it 'does not display scan thumbnails for Gutenberg books' do
      expect(rendered).not_to have_selector('.toc-scan-thumb')
    end

    it 'does not display zoom controls for Gutenberg books' do
      expect(rendered).not_to have_selector('.zoomInBtn')
      expect(rendered).not_to have_selector('.zoomOutBtn')
    end

    it 'does not display the scan zoom modal for Gutenberg books' do
      expect(rendered).not_to have_selector('#scanZoomModalBody')
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
      assign(:is_gutenberg, false)
      render partial: 'tocs/toc_body_tab', locals: { f: double('form', label: '', text_area: '') }
    end

    it 'does not display the reference toggle button' do
      expect(rendered).not_to have_selector('button#toggleReference')
    end

    it 'does not display the reference panel' do
      expect(rendered).not_to have_selector('#referencePanel')
    end

    it 'displays only the editing panel' do
      expect(rendered).to have_selector('.editing-panel')
    end

    it 'displays magic trim button' do
      expect(rendered).to have_selector('button#magic_trim')
    end
  end

  context 'with Gutenberg book without fulltext' do
    let(:toc) do
      Toc.create!(
        book_uri: 'https://www.gutenberg.org/ebooks/9999',
        title: 'Book without Fulltext',
        source: 'gutenberg',
        status: :empty
      )
    end

    before do
      assign(:toc, toc)
      assign(:is_gutenberg, true)
      assign(:fulltext_url, nil)
      render partial: 'tocs/toc_body_tab', locals: { f: double('form', label: '', text_area: '') }
    end

    it 'does not display the reference toggle button' do
      expect(rendered).not_to have_selector('button#toggleReference')
    end

    it 'does not display the reference panel' do
      expect(rendered).not_to have_selector('#referencePanel')
    end
  end

  context 'layout structure' do
    let(:toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book with Scans',
        source: 'openlibrary',
        status: :pages_marked,
        toc_page_urls: "https://archive.org/download/book1/page1.jpg"
      )
    end

    before do
      assign(:toc, toc)
      assign(:is_gutenberg, false)
      render partial: 'tocs/toc_body_tab', locals: { f: double('form', label: '', text_area: '') }
    end

    it 'wraps content in toc-body-section' do
      expect(rendered).to have_selector('.toc-body-section')
    end

    it 'contains toc-body-layout container' do
      expect(rendered).to have_selector('.toc-body-layout')
    end

    it 'reference panel has correct structure' do
      expect(rendered).to have_selector('.reference-panel .panel.panel-default', visible: :all)
      expect(rendered).to have_selector('.reference-panel .panel-heading', visible: :all)
      expect(rendered).to have_selector('.reference-panel .panel-body', visible: :all)
    end

    it 'editing panel contains form elements' do
      expect(rendered).to have_selector('.editing-panel .form-group')
    end
  end

  context 'markdown help section' do
    let(:toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book',
        source: 'openlibrary',
        status: :empty
      )
    end

    before do
      assign(:toc, toc)
      assign(:is_gutenberg, false)
      render partial: 'tocs/toc_body_tab', locals: { f: double('form', label: '', text_area: '') }
    end

    it 'displays markdown help section' do
      expect(rendered).to have_selector('.markdown-help-section')
    end

    it 'displays collapsible markdown help' do
      expect(rendered).to have_selector('#markdownHelp.collapse')
    end
  end
end

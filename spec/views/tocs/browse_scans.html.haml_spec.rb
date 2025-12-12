require 'rails_helper'

RSpec.describe "tocs/browse_scans.html.haml", type: :view do
  let(:toc) do
    Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Book for Scanning',
      status: :empty
    )
  end

  let(:pages) do
    [
      { page_number: 0, url: 'https://archive.org/download/book/page/n0.jpg', thumb_url: 'https://archive.org/download/book/page/n0.jpg?scale=8' },
      { page_number: 1, url: 'https://archive.org/download/book/page/n1.jpg', thumb_url: 'https://archive.org/download/book/page/n1.jpg?scale=8' },
      { page_number: 2, url: 'https://archive.org/download/book/page/n2.jpg', thumb_url: 'https://archive.org/download/book/page/n2.jpg?scale=8' }
    ]
  end

  let(:metadata) { { imagecount: 100 } }

  before do
    assign(:toc, toc)
    assign(:pages, pages)
    assign(:marked_pages, [])
    assign(:current_page, 1)
    assign(:page_size, 20)
    assign(:total_pages, 5)
    assign(:metadata, metadata)
  end

  context 'page structure and content' do
    before { render }

    it 'displays the book title' do
      expect(rendered).to have_content('Test Book for Scanning')
    end

    it 'displays page navigation information' do
      expect(rendered).to have_content('Viewing pages')
      expect(rendered).to have_content('100')
    end

    it 'displays instructions for selecting pages' do
      expect(rendered).to have_selector('.alert.alert-info')
    end

    it 'renders a card for each page' do
      expect(rendered).to have_selector('.scan-card', count: 3)
    end
  end

  context 'image loading placeholders' do
    before { render }

    it 'renders image loading containers for each page' do
      expect(rendered).to have_selector('.image-loading-container', count: 3)
    end

    it 'sets correct height for image containers' do
      expect(rendered).to have_selector('.image-loading-container[style*="height: 200px"]', count: 3)
    end

    it 'renders images with image-loader class' do
      expect(rendered).to have_selector('img.image-loader', count: 3)
    end

    it 'renders images with card-img-top class' do
      expect(rendered).to have_selector('img.card-img-top', count: 3)
    end

    it 'renders loading spinners for each image' do
      expect(rendered).to have_selector('.image-loading-spinner', count: 3)
      expect(rendered).to have_selector('.image-spinner', count: 3)
    end

    it 'assigns unique image IDs to each image and spinner' do
      expect(rendered).to have_selector('[data-image-id="browse-0"]', count: 3) # container, img, spinner
      expect(rendered).to have_selector('[data-image-id="browse-1"]', count: 3)
      expect(rendered).to have_selector('[data-image-id="browse-2"]', count: 3)
    end

    it 'includes thumbnail URLs with scale parameter' do
      expect(rendered).to have_selector('img[src*="scale=8"]', count: 3)
    end
  end

  context 'page selection functionality' do
    before { render }

    it 'renders checkboxes for each page' do
      expect(rendered).to have_selector('input[type="checkbox"].page-checkbox', count: 3)
    end

    it 'renders page labels' do
      expect(rendered).to have_content('Page 0')
      expect(rendered).to have_content('Page 1')
      expect(rendered).to have_content('Page 2')
    end

    it 'renders view full size links' do
      expect(rendered).to have_selector('a.view-full-link', count: 3)
    end
  end

  context 'when pages are marked as selected' do
    before do
      assign(:marked_pages, ['https://archive.org/download/book/page/n1.jpg'])
      render
    end

    it 'applies selected class to marked cards' do
      expect(rendered).to have_selector('.scan-card.selected', count: 1)
    end

    it 'checks the checkbox for marked pages' do
      expect(rendered).to have_selector('input[type="checkbox"][checked]', count: 1)
    end
  end

  context 'pagination controls' do
    before { render }

    it 'displays pagination controls' do
      expect(rendered).to have_selector('nav[aria-label="Page navigation"]')
      expect(rendered).to have_selector('.pagination')
    end

    it 'displays first and previous links' do
      expect(rendered).to have_content('First')
      expect(rendered).to have_content('Previous')
    end

    it 'displays next and last links' do
      expect(rendered).to have_content('Next')
      expect(rendered).to have_content('Last')
    end
  end

  context 'form submission' do
    before { render }

    it 'renders a form for marking pages' do
      expect(rendered).to have_selector('form#mark_pages_form')
    end

    it 'renders save and cancel buttons' do
      expect(rendered).to have_button('Save Marked Pages')
      expect(rendered).to have_link('Cancel')
    end

    it 'includes no explicit TOC checkbox' do
      expect(rendered).to have_selector('input#no_explicit_toc[type="checkbox"]')
    end
  end
end

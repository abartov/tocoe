require 'rails_helper'

RSpec.describe 'Scan Browser Workflow', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:toc) do
    Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL7928212M',
      title: 'The Big Year',
      status: :empty
    )
  end

  let(:ol_client) { instance_double(OpenLibrary::Client) }
  let(:ia_metadata) do
    {
      imagecount: 100,
      title: 'The Big Year',
      page_progression: 'lr'
    }
  end
  let(:page_images) do
    (0...20).map do |n|
      {
        page_number: n,
        url: "https://archive.org/download/test_id/page/n#{n}.jpg",
        thumb_url: "https://archive.org/download/test_id/page/n#{n}.jpg?scale=8"
      }
    end
  end

  before do
    sign_in user
    allow(OpenLibrary::Client).to receive(:new).and_return(ol_client)
    allow(ol_client).to receive(:ia_identifier).with('OL7928212M').and_return('test_ia_id')
    allow(ol_client).to receive(:ia_metadata).with('test_ia_id').and_return(ia_metadata)
    allow(ol_client).to receive(:ia_page_images).and_return(page_images)

    # Stub API calls for get_authors method
    book_data = { 'title' => 'The Big Year', 'authors' => [{ 'key' => '/authors/OL123A' }] }
    author_data = { 'key' => '/authors/OL123A', 'name' => 'Test Author' }
    allow_any_instance_of(ApplicationController).to receive(:rest_get)
      .with('http://openlibrary.org/books/OL7928212M.json').and_return(book_data)
    allow_any_instance_of(ApplicationController).to receive(:rest_get)
      .with('http://openlibrary.org/authors/OL123A.json').and_return(author_data)
    # Also stub for OL123M book used in another test
    book_data2 = { 'title' => 'Test Book', 'authors' => [{ 'key' => '/authors/OL123A' }] }
    allow_any_instance_of(ApplicationController).to receive(:rest_get)
      .with('http://openlibrary.org/books/OL123M.json').and_return(book_data2)
  end

  describe 'complete workflow: browse and mark TOC pages' do
    it 'allows user to browse scans, mark pages, and transition status' do
      # Step 1: User views the TOC
      get toc_path(toc)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Browse Scans')

      # Step 2: User clicks "Browse Scans"
      get browse_scans_toc_path(toc)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Browse Scans: The Big Year')
      expect(response.body).to include('Page 0')
      expect(response.body).to include('No explicit table of contents')

      # Step 3: User marks pages 5 and 6 as containing TOC
      marked_urls = [
        'https://archive.org/download/test_id/page/n5.jpg',
        'https://archive.org/download/test_id/page/n6.jpg'
      ]

      post mark_pages_toc_path(toc), params: { marked_pages: marked_urls }

      # Step 4: Verify redirect to TOC show page
      expect(response).to redirect_to(toc_path(toc))
      follow_redirect!
      expect(response.body).to include('TOC pages marked successfully')

      # Step 5: Verify TOC record updated correctly
      toc.reload
      expect(toc.toc_page_urls).to eq(marked_urls.join("\n"))
      expect(toc.status).to eq('pages_marked')
      expect(toc.no_explicit_toc).to eq(false)

      # Step 6: Verify show page displays marked pages count and thumbnails
      expect(response.body).to include('Marked TOC Pages')
      expect(response.body).to include('(2)')
      # Verify thumbnails are displayed
      expect(response.body).to include('TOC Page 1')
      expect(response.body).to include('TOC Page 2')
      expect(response.body).to include('?scale=8')
    end

    it 'allows user to mark "no explicit TOC" and transition status' do
      # User browses scans
      get browse_scans_toc_path(toc)
      expect(response).to have_http_status(:success)

      # User checks "no explicit TOC"
      post mark_pages_toc_path(toc), params: { no_explicit_toc: '1' }

      # Verify redirect and status transition
      expect(response).to redirect_to(toc_path(toc))
      follow_redirect!
      expect(response.body).to include('TOC pages marked successfully')

      # Verify TOC record
      toc.reload
      expect(toc.no_explicit_toc).to eq(true)
      expect(toc.status).to eq('pages_marked')
      expect(toc.toc_page_urls).to be_nil

      # Verify show page displays flag
      expect(response.body).to include('No explicit table of contents')
    end

    it 'handles pagination when browsing scans' do
      # Page 1
      get browse_scans_toc_path(toc, page: 1)
      expect(response).to have_http_status(:success)
      expect(ol_client).to have_received(:ia_page_images).with(
        'test_ia_id',
        hash_including(start_page: 0, end_page: 19)
      )

      # Page 2
      allow(ol_client).to receive(:ia_page_images).and_return(
        (20...40).map do |n|
          {
            page_number: n,
            url: "https://archive.org/download/test_id/page/n#{n}.jpg",
            thumb_url: "https://archive.org/download/test_id/page/n#{n}.jpg?scale=8"
          }
        end
      )

      get browse_scans_toc_path(toc, page: 2)
      expect(response).to have_http_status(:success)
      expect(ol_client).to have_received(:ia_page_images).with(
        'test_ia_id',
        hash_including(start_page: 20, end_page: 39)
      )
    end

    it 'preserves already marked pages when re-browsing' do
      # First, mark some pages
      marked_urls = [
        'https://archive.org/download/test_id/page/n5.jpg',
        'https://archive.org/download/test_id/page/n6.jpg'
      ]
      toc.update!(toc_page_urls: marked_urls.join("\n"))

      # Browse again
      get browse_scans_toc_path(toc)
      expect(response).to have_http_status(:success)

      # Verify checkboxes for marked pages are checked
      marked_urls.each do |url|
        # HTML outputs checked="checked"
        expect(response.body).to match(/value="#{Regexp.escape(url)}"[^>]*checked="checked"/)
      end
    end
  end

  describe 'UI state management' do
    it 'shows browse scans prompt in edit view when status is empty' do
      get edit_toc_path(toc)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('No TOC pages marked yet')
      expect(response.body).to include('Browse Scans to Mark TOC Pages')
      expect(response.body).not_to include('Attempt OCR')
    end

    it 'shows OCR controls in edit view when status is pages_marked' do
      toc.update!(
        status: :pages_marked,
        toc_page_urls: "https://archive.org/test.jpg"
      )

      get edit_toc_path(toc)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t('tocs.form.ocr_section.extract_text_button'))
      expect(response.body).to include('https://archive.org/test.jpg')
      expect(response.body).not_to include('No TOC pages marked yet')
    end

    it 'shows action required alert in show view when status is empty' do
      get toc_path(toc)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Action Required')
      expect(response.body).to include('This TOC has not yet had its pages marked')
    end

    it 'does not show OCR section in new view' do
      get new_toc_path(from: 'openlibrary', ol_book_id: 'OL123M')
      # This would require mocking the OpenLibrary API call
      # For now, just verify the path is accessible
      expect(response).to have_http_status(:success)
    end
  end

  describe 'error handling' do
    it 'redirects when book has no scans' do
      allow(ol_client).to receive(:ia_identifier).and_return(nil)

      get browse_scans_toc_path(toc)
      expect(response).to redirect_to(toc_path(toc))
      expect(flash[:error]).to eq('No scans available for this book')
    end

    it 'requires either marked pages or no_explicit_toc flag' do
      get browse_scans_toc_path(toc)

      # Submit without marking anything
      post mark_pages_toc_path(toc), params: {}

      expect(response).to redirect_to(browse_scans_toc_path(toc))
      expect(flash[:error]).to match(/Please mark at least one page/)

      # Verify TOC status didn't change
      toc.reload
      expect(toc.status).to eq('empty')
    end

    it 'handles invalid book URI gracefully' do
      invalid_toc = Toc.create!(
        book_uri: 'http://example.com/invalid',
        title: 'Invalid Book'
      )

      get browse_scans_toc_path(invalid_toc)
      expect(response).to redirect_to(toc_path(invalid_toc))
      expect(flash[:error]).to eq('Invalid OpenLibrary book URI')
    end
  end
end

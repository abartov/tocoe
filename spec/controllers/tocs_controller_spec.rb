require 'rails_helper'

RSpec.describe TocsController, type: :controller do
  let(:toc) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL123M', title: 'Test Book') }
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

  # All tests run with authenticated user
  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'excludes verified TOCs by default' do
      verified_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL1M', title: 'Verified', status: :verified)
      pending_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL2M', title: 'Pending', status: :pages_marked)

      get :index

      expect(assigns(:tocs)).to include(pending_toc)
      expect(assigns(:tocs)).not_to include(verified_toc)
    end

    it 'shows all TOCs when show_all parameter is true' do
      verified_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL1M', title: 'Verified', status: :verified)
      pending_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL2M', title: 'Pending', status: :pages_marked)

      get :index, params: { show_all: 'true' }

      expect(assigns(:tocs)).to include(verified_toc)
      expect(assigns(:tocs)).to include(pending_toc)
    end

    it 'orders TOCs by updated_at descending by default' do
      old_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL1M', title: 'Old', status: :empty, updated_at: 2.days.ago)
      new_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL2M', title: 'New', status: :empty, updated_at: 1.day.ago)

      get :index

      expect(assigns(:tocs).first).to eq(new_toc)
      expect(assigns(:tocs).last).to eq(old_toc)
    end

    it 'filters by status parameter' do
      empty_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL1M', title: 'Empty', status: :empty)
      verified_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL2M', title: 'Verified', status: :verified)

      get :index, params: { status: 'empty' }

      expect(assigns(:tocs)).to include(empty_toc)
      expect(assigns(:tocs)).not_to include(verified_toc)
    end

    it 'orders by created_at descending when showing empty status' do
      old_empty = Toc.create!(book_uri: 'http://openlibrary.org/books/OL1M', title: 'Old', status: :empty, created_at: 2.days.ago)
      new_empty = Toc.create!(book_uri: 'http://openlibrary.org/books/OL2M', title: 'New', status: :empty, created_at: 1.day.ago)

      get :index, params: { status: 'empty' }

      expect(assigns(:tocs).first).to eq(new_empty)
      expect(assigns(:tocs).last).to eq(old_empty)
    end
  end

  describe 'POST #create_multiple' do
    it 'creates multiple TOCs from book IDs' do
      book_data = { 'title' => 'Test Book' }
      allow(controller).to receive(:rest_get).and_return(book_data)

      expect {
        post :create_multiple, params: { book_ids: ['OL1M', 'OL2M'] }
      }.to change(Toc, :count).by(2)

      expect(flash[:notice]).to match(/Successfully created 2 TOCs/)
      expect(response).to redirect_to(tocs_path(status: 'empty'))
    end

    it 'creates TOCs with empty status' do
      book_data = { 'title' => 'Test Book' }
      allow(controller).to receive(:rest_get).and_return(book_data)

      post :create_multiple, params: { book_ids: ['OL1M'] }

      toc = Toc.last
      expect(toc.status).to eq('empty')
      expect(toc.book_uri).to eq('http://openlibrary.org/books/OL1M')
    end

    it 'handles no books selected' do
      post :create_multiple, params: { book_ids: [] }

      expect(flash[:error]).to eq('No books selected')
      expect(response).to redirect_to(publications_search_path)
    end

    it 'handles API errors gracefully' do
      allow(controller).to receive(:rest_get).and_raise(StandardError.new('API error'))

      post :create_multiple, params: { book_ids: ['OL1M'] }

      expect(Toc.count).to eq(0)
      expect(flash[:error]).to eq('Failed to create any TOCs')
    end
  end

  describe 'GET #browse_scans' do
    context 'with valid OpenLibrary book URI' do
      let(:ol_client) { instance_double(OpenLibrary::Client) }
      let(:ia_metadata) { { imagecount: 50, title: 'Test Book', page_progression: 'lr' } }
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
        allow(OpenLibrary::Client).to receive(:new).and_return(ol_client)
        allow(ol_client).to receive(:ia_identifier).with('OL123M').and_return('test_ia_id')
        allow(ol_client).to receive(:ia_metadata).with('test_ia_id').and_return(ia_metadata)
        allow(ol_client).to receive(:ia_page_images).and_return(page_images)
      end

      it 'fetches and displays page scans' do
        get :browse_scans, params: { id: toc.id }

        expect(response).to have_http_status(:success)
        expect(assigns(:ia_id)).to eq('test_ia_id')
        expect(assigns(:metadata)).to eq(ia_metadata)
        expect(assigns(:pages)).to eq(page_images)
      end

      it 'handles pagination' do
        get :browse_scans, params: { id: toc.id, page: 2 }

        expect(assigns(:current_page)).to eq(2)
        expect(ol_client).to have_received(:ia_page_images).with(
          'test_ia_id',
          hash_including(start_page: 20, end_page: 39)
        )
      end

      it 'parses already marked pages' do
        toc.update!(toc_page_urls: "https://archive.org/page1.jpg\nhttps://archive.org/page2.jpg")

        get :browse_scans, params: { id: toc.id }

        expect(assigns(:marked_pages)).to eq([
          'https://archive.org/page1.jpg',
          'https://archive.org/page2.jpg'
        ])
      end
    end

    context 'with invalid book URI' do
      let(:invalid_toc) { Toc.create!(book_uri: 'http://example.com/invalid', title: 'Invalid') }

      it 'redirects with error for invalid URI' do
        get :browse_scans, params: { id: invalid_toc.id }

        expect(response).to redirect_to(invalid_toc)
        expect(flash[:error]).to eq('Invalid OpenLibrary book URI')
      end
    end

    context 'when no scans available' do
      let(:ol_client) { instance_double(OpenLibrary::Client) }

      before do
        allow(OpenLibrary::Client).to receive(:new).and_return(ol_client)
        allow(ol_client).to receive(:ia_identifier).and_return(nil)
      end

      it 'redirects with error' do
        get :browse_scans, params: { id: toc.id }

        expect(response).to redirect_to(toc)
        expect(flash[:error]).to eq('No scans available for this book')
      end
    end

    context 'when metadata fetch fails' do
      let(:ol_client) { instance_double(OpenLibrary::Client) }

      before do
        allow(OpenLibrary::Client).to receive(:new).and_return(ol_client)
        allow(ol_client).to receive(:ia_identifier).and_return('test_id')
        allow(ol_client).to receive(:ia_metadata).and_return(nil)
      end

      it 'redirects with error' do
        get :browse_scans, params: { id: toc.id }

        expect(response).to redirect_to(toc)
        expect(flash[:error]).to eq('Unable to fetch scan metadata')
      end
    end
  end

  describe 'POST #mark_pages' do
    it 'saves marked pages and transitions to pages_marked status' do
      marked_urls = [
        'https://archive.org/download/test/page/n5.jpg',
        'https://archive.org/download/test/page/n6.jpg'
      ]

      post :mark_pages, params: { id: toc.id, marked_pages: marked_urls }

      toc.reload
      expect(toc.toc_page_urls).to eq(marked_urls.join("\n"))
      expect(toc.status).to eq('pages_marked')
      expect(toc.no_explicit_toc).to eq(false)
      expect(response).to redirect_to(toc)
      expect(flash[:notice]).to eq('TOC pages marked successfully')
    end

    it 'saves no_explicit_toc flag and transitions status' do
      post :mark_pages, params: { id: toc.id, no_explicit_toc: '1' }

      toc.reload
      expect(toc.no_explicit_toc).to eq(true)
      expect(toc.status).to eq('pages_marked')
      expect(response).to redirect_to(toc)
    end

    it 'requires either marked pages or no_explicit_toc' do
      post :mark_pages, params: { id: toc.id }

      expect(response).to redirect_to(browse_scans_toc_path(toc))
      expect(flash[:error]).to match(/Please mark at least one page/)
    end

    it 'handles save failure' do
      allow_any_instance_of(Toc).to receive(:save).and_return(false)

      post :mark_pages, params: {
        id: toc.id,
        marked_pages: ['https://archive.org/test.jpg']
      }

      expect(response).to redirect_to(browse_scans_toc_path(toc))
      expect(flash[:error]).to eq('Failed to save marked pages')
    end
  end

  describe '#parse_marked_pages' do
    it 'parses newline-separated URLs' do
      urls = "https://archive.org/page1.jpg\nhttps://archive.org/page2.jpg\nhttps://archive.org/page3.jpg"
      result = controller.send(:parse_marked_pages, urls)

      expect(result).to eq([
        'https://archive.org/page1.jpg',
        'https://archive.org/page2.jpg',
        'https://archive.org/page3.jpg'
      ])
    end

    it 'returns empty array for nil input' do
      result = controller.send(:parse_marked_pages, nil)
      expect(result).to eq([])
    end

    it 'returns empty array for blank input' do
      result = controller.send(:parse_marked_pages, '')
      expect(result).to eq([])
    end

    it 'strips whitespace and rejects blank lines' do
      urls = "https://archive.org/page1.jpg\n  \n  https://archive.org/page2.jpg  \n\n"
      result = controller.send(:parse_marked_pages, urls)

      expect(result).to eq([
        'https://archive.org/page1.jpg',
        'https://archive.org/page2.jpg'
      ])
    end
  end

  describe 'POST #do_ocr' do
    context 'with provided URLs' do
      it 'uses the provided URLs for OCR' do
        allow(controller).to receive(:valid?).and_return(true)
        allow(controller).to receive(:get_ocr_from_service).and_return('OCR result')

        post :do_ocr, params: { ocr_images: 'https://archive.org/test.jpg' }, xhr: true

        expect(controller).to have_received(:get_ocr_from_service).with('https://archive.org/test.jpg')
        expect(assigns(:results)).to include('OCR result')
      end
    end

    context 'without provided URLs but with marked TOC pages' do
      it 'falls back to using marked TOC pages' do
        toc_with_pages = Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL123M',
          title: 'Test',
          toc_page_urls: "https://archive.org/page1.jpg\nhttps://archive.org/page2.jpg"
        )

        allow(controller).to receive(:valid?).and_return(true)
        allow(controller).to receive(:get_ocr_from_service).and_return('OCR result')

        post :do_ocr, params: { toc_id: toc_with_pages.id, ocr_images: '' }, xhr: true

        expect(controller).to have_received(:get_ocr_from_service).twice
        expect(assigns(:results)).to include('OCR result')
      end
    end

    context 'without URLs and without marked pages' do
      it 'processes empty list gracefully' do
        post :do_ocr, params: { ocr_images: '' }, xhr: true

        expect(assigns(:results)).to eq('')
      end
    end

    context 'JavaScript response format' do
      render_views

      it 'wraps results in PRE tag and re-enables submit button' do
        allow(controller).to receive(:valid?).and_return(true)
        allow(controller).to receive(:get_ocr_from_service).and_return("Line 1\nLine 2\nLine 3")

        post :do_ocr, params: { ocr_images: 'https://archive.org/test.jpg' }, format: :js

        expect(response.body).to include('<pre>')
        expect(response.body).to include('</pre>')
        expect(response.body).to include('$("#ocr_submit").prop(\'disabled\', false)')
        expect(response.body).to include('$("#ocr_working").hide()')
        expect(response.body).to include('$("#paste_ocr").show()')
      end
    end
  end

  describe 'POST #mark_transcribed' do
    let(:pages_marked_toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book',
        status: :pages_marked
      )
    end

    it 'marks TOC as transcribed and sets contributor' do
      post :mark_transcribed, params: { id: pages_marked_toc.id }

      pages_marked_toc.reload
      expect(pages_marked_toc.status).to eq('transcribed')
      expect(pages_marked_toc.contributor_id).to eq(user.id)
      expect(response).to redirect_to(pages_marked_toc)
      expect(flash[:notice]).to eq('TOC marked as transcribed successfully')
    end

    it 'rejects if TOC is not in pages_marked status' do
      empty_toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test',
        status: :empty
      )

      post :mark_transcribed, params: { id: empty_toc.id }

      empty_toc.reload
      expect(empty_toc.status).to eq('empty')
      expect(flash[:error]).to eq('TOC must be in pages_marked status to mark as transcribed')
    end
  end

  describe 'POST #verify' do
    let(:contributor) { User.create!(email: 'contributor@example.com', password: 'password', name: 'Contributor') }
    let(:reviewer) { User.create!(email: 'reviewer@example.com', password: 'password', name: 'Reviewer') }

    let(:transcribed_toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book',
        status: :transcribed,
        contributor_id: contributor.id
      )
    end

    context 'when reviewer is different from contributor' do
      before { sign_in reviewer }

      it 'verifies TOC and sets reviewer' do
        post :verify, params: { id: transcribed_toc.id }

        transcribed_toc.reload
        expect(transcribed_toc.status).to eq('verified')
        expect(transcribed_toc.reviewer_id).to eq(reviewer.id)
        expect(response).to redirect_to(transcribed_toc)
        expect(flash[:notice]).to eq('TOC verified successfully')
      end
    end

    context 'when contributor attempts to verify their own TOC' do
      before { sign_in contributor }

      it 'rejects verification and keeps TOC in transcribed status' do
        post :verify, params: { id: transcribed_toc.id }

        transcribed_toc.reload
        expect(transcribed_toc.status).to eq('transcribed')
        expect(transcribed_toc.reviewer_id).to be_nil
        expect(response).to redirect_to(transcribed_toc)
        expect(flash[:error]).to eq('You cannot verify a TOC that you contributed')
      end
    end

    it 'rejects if TOC is not in transcribed status' do
      pages_marked_toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test',
        status: :pages_marked
      )

      post :verify, params: { id: pages_marked_toc.id }

      pages_marked_toc.reload
      expect(pages_marked_toc.status).to eq('pages_marked')
      expect(flash[:error]).to eq('TOC must be in transcribed status to verify')
    end
  end

  describe 'DELETE #destroy' do
    let(:admin_user) { User.create!(email: 'admin@example.com', password: 'password', admin: true) }
    let(:regular_user) { User.create!(email: 'user@example.com', password: 'password', admin: false) }
    let!(:toc_to_destroy) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL999M', title: 'To Delete') }

    context 'when user is an admin' do
      before { sign_in admin_user }

      it 'allows the admin to destroy the TOC' do
        expect {
          delete :destroy, params: { id: toc_to_destroy.id }
        }.to change(Toc, :count).by(-1)

        expect(response).to redirect_to(tocs_url)
        expect(flash[:notice]).to eq('Toc was successfully destroyed.')
      end
    end

    context 'when user is not an admin' do
      before { sign_in regular_user }

      it 'prevents non-admin from destroying the TOC' do
        expect {
          delete :destroy, params: { id: toc_to_destroy.id }
        }.not_to change(Toc, :count)

        expect(response).to redirect_to(tocs_url)
        expect(flash[:error]).to eq('You must be an admin to perform this action')
      end

      it 'does not destroy the TOC' do
        delete :destroy, params: { id: toc_to_destroy.id }

        expect(Toc.exists?(toc_to_destroy.id)).to be true
      end
    end
  end
end

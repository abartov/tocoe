require 'rails_helper'

RSpec.describe TocsController, type: :controller do
  let(:toc) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL123M', title: 'Test Book') }
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

  # All tests run with authenticated user
  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'includes authors association in the query' do
      toc1 = Toc.create!(book_uri: 'http://openlibrary.org/books/OL1M', title: 'Book 1')
      author1 = Person.create!(name: 'Author One')
      PeopleToc.create!(person: author1, toc: toc1)

      get :index

      # Verify authors are accessible on the loaded TOCs
      expect(assigns(:tocs).first.authors).to include(author1)
    end

    it 'excludes verified TOCs by default' do
      verified_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL1M', title: 'Verified', status: :verified)
      pending_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL2M', title: 'Pending', status: :pages_marked)

      get :index

      expect(assigns(:tocs)).to include(pending_toc)
      expect(assigns(:tocs)).not_to include(verified_toc)
    end

    it 'excludes current user\'s TOCs by default' do
      # Create TOCs by different users
      other_user = User.create!(email: 'other@example.com', password: 'password123')
      own_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL1M', title: 'My TOC', status: :transcribed, contributor: user)
      other_toc = Toc.create!(book_uri: 'http://openlibrary.org/books/OL2M', title: 'Other TOC', status: :transcribed, contributor: other_user)

      get :index

      expect(assigns(:tocs)).to include(other_toc)
      expect(assigns(:tocs)).not_to include(own_toc)
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

    describe 'sorting' do
      let!(:toc_a) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL1M', title: 'Alpha Book', status: :empty, created_at: 3.days.ago) }
      let!(:toc_b) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL2M', title: 'Beta Book', status: :pages_marked, created_at: 2.days.ago) }
      let!(:toc_c) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL3M', title: 'Gamma Book', status: :transcribed, created_at: 1.day.ago) }

      it 'sorts by title ascending' do
        get :index, params: { sort: 'title', direction: 'asc', show_all: 'true' }

        tocs = assigns(:tocs).to_a
        expect(tocs[0]).to eq(toc_a)
        expect(tocs[1]).to eq(toc_b)
        expect(tocs[2]).to eq(toc_c)
      end

      it 'sorts by title descending' do
        get :index, params: { sort: 'title', direction: 'desc', show_all: 'true' }

        tocs = assigns(:tocs).to_a
        expect(tocs[0]).to eq(toc_c)
        expect(tocs[1]).to eq(toc_b)
        expect(tocs[2]).to eq(toc_a)
      end

      it 'sorts by status ascending' do
        get :index, params: { sort: 'status', direction: 'asc', show_all: 'true' }

        tocs = assigns(:tocs).to_a
        expect(tocs[0]).to eq(toc_a) # empty
        expect(tocs[1]).to eq(toc_b) # pages_marked
        expect(tocs[2]).to eq(toc_c) # transcribed
      end

      it 'sorts by status descending' do
        get :index, params: { sort: 'status', direction: 'desc', show_all: 'true' }

        tocs = assigns(:tocs).to_a
        expect(tocs[0]).to eq(toc_c) # transcribed
        expect(tocs[1]).to eq(toc_b) # pages_marked
        expect(tocs[2]).to eq(toc_a) # empty
      end

      it 'sorts by created_at ascending' do
        get :index, params: { sort: 'created_at', direction: 'asc', show_all: 'true' }

        tocs = assigns(:tocs).to_a
        expect(tocs[0]).to eq(toc_a) # oldest
        expect(tocs[1]).to eq(toc_b)
        expect(tocs[2]).to eq(toc_c) # newest
      end

      it 'sorts by created_at descending' do
        get :index, params: { sort: 'created_at', direction: 'desc', show_all: 'true' }

        tocs = assigns(:tocs).to_a
        expect(tocs[0]).to eq(toc_c) # newest
        expect(tocs[1]).to eq(toc_b)
        expect(tocs[2]).to eq(toc_a) # oldest
      end

      context 'sorting by contributor' do
        let(:contributor1) { User.create!(email: 'alice@example.com', password: 'password', name: 'Alice') }
        let(:contributor2) { User.create!(email: 'bob@example.com', password: 'password', name: 'Bob') }
        let!(:toc_with_contributor1) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL4M', title: 'Book 1', contributor: contributor1) }
        let!(:toc_with_contributor2) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL5M', title: 'Book 2', contributor: contributor2) }
        let!(:toc_without_contributor) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL6M', title: 'Book 3') }

        it 'sorts by contributor name ascending' do
          get :index, params: { sort: 'contributor_id', direction: 'asc', show_all: 'true' }

          tocs = assigns(:tocs)
          # NULLs typically come first in SQL ascending order
          expect(tocs).to include(toc_with_contributor1, toc_with_contributor2, toc_without_contributor)
        end

        it 'sorts by contributor name descending' do
          get :index, params: { sort: 'contributor_id', direction: 'desc', show_all: 'true' }

          tocs = assigns(:tocs)
          expect(tocs).to include(toc_with_contributor1, toc_with_contributor2, toc_without_contributor)
        end
      end

      context 'sorting by reviewer' do
        let(:reviewer1) { User.create!(email: 'reviewer1@example.com', password: 'password', name: 'Alice Reviewer') }
        let(:reviewer2) { User.create!(email: 'reviewer2@example.com', password: 'password', name: 'Bob Reviewer') }
        let!(:toc_with_reviewer1) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL7M', title: 'Book 1', reviewer: reviewer1) }
        let!(:toc_with_reviewer2) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL8M', title: 'Book 2', reviewer: reviewer2) }
        let!(:toc_without_reviewer) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL9M', title: 'Book 3') }

        it 'sorts by reviewer name ascending' do
          get :index, params: { sort: 'reviewer_id', direction: 'asc', show_all: 'true' }

          tocs = assigns(:tocs)
          expect(tocs).to include(toc_with_reviewer1, toc_with_reviewer2, toc_without_reviewer)
        end

        it 'sorts by reviewer name descending' do
          get :index, params: { sort: 'reviewer_id', direction: 'desc', show_all: 'true' }

          tocs = assigns(:tocs)
          expect(tocs).to include(toc_with_reviewer1, toc_with_reviewer2, toc_without_reviewer)
        end
      end

      it 'ignores invalid sort column and uses default sorting' do
        get :index, params: { sort: 'invalid_column', direction: 'asc', show_all: 'true' }

        # Should fall back to default sorting (updated_at desc)
        expect(response).to have_http_status(:success)
        expect(assigns(:tocs)).to be_present
      end

      it 'defaults to ascending when direction is not specified' do
        get :index, params: { sort: 'title', show_all: 'true' }

        tocs = assigns(:tocs).to_a
        expect(tocs[0]).to eq(toc_a) # Alpha
        expect(tocs[1]).to eq(toc_b) # Beta
        expect(tocs[2]).to eq(toc_c) # Gamma
      end

      it 'preserves status filter while sorting' do
        get :index, params: { sort: 'title', direction: 'asc', status: 'empty' }

        tocs = assigns(:tocs).to_a
        expect(tocs).to eq([toc_a])
      end
    end
  end

  describe 'GET #download' do
    let(:toc_with_content) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Sample Book',
        toc_body: "# Chapter 1\n## Section 1.1\n# Chapter 2 || John Doe",
        status: :verified
      )
    end

    it 'downloads TOC as plaintext by default' do
      get :download, params: { id: toc_with_content.id }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/plain')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include('sample_book.txt')
      expect(response.body).to include('Sample Book')
      expect(response.body).to include('Chapter 1')
    end

    it 'downloads TOC as plaintext when format is plaintext' do
      get :download, params: { id: toc_with_content.id, format: 'plaintext' }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/plain')
      expect(response.headers['Content-Disposition']).to include('sample_book.txt')
      expect(response.body).to include('Chapter 1')
      expect(response.body).to include('Chapter 2 (John Doe)')
    end

    it 'downloads TOC as markdown when format is markdown' do
      get :download, params: { id: toc_with_content.id, format: 'markdown' }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/markdown')
      expect(response.headers['Content-Disposition']).to include('sample_book.md')
      expect(response.body).to include('# Sample Book')
      expect(response.body).to include('## Table of Contents')
      expect(response.body).to include('# Chapter 1')
    end

    it 'downloads TOC as JSON when format is json' do
      get :download, params: { id: toc_with_content.id, format: 'json' }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.headers['Content-Disposition']).to include('sample_book.json')

      json_response = JSON.parse(response.body)
      expect(json_response['toc']['title']).to eq('Sample Book')
      expect(json_response['toc']['entries'].length).to eq(3)
      expect(json_response['toc']['entries'][0]['title']).to eq('Chapter 1')
      expect(json_response['toc']['entries'][2]['authors']).to eq(['John Doe'])
    end

    it 'sanitizes filename from TOC title' do
      toc_with_special_chars = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL456M',
        title: 'Book: A Study & Research!',
        toc_body: '# Chapter 1',
        status: :verified
      )

      get :download, params: { id: toc_with_special_chars.id, format: 'plaintext' }

      expect(response.headers['Content-Disposition']).to include('book_a_study_research.txt')
    end

    it 'handles TOC with no toc_body' do
      toc_no_body = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL789M',
        title: 'Empty TOC',
        status: :empty
      )

      get :download, params: { id: toc_no_body.id, format: 'plaintext' }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Empty TOC')
      expect(response.body).to include('No table of contents has been transcribed yet')
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
        status: :pages_marked,
        toc_body: "# Essay 1\n# Essay 2",
        toc_page_urls: "https://example.com/page1.jpg\nhttps://example.com/page2.jpg"
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

  describe '#map_authors' do
    it 'adds standardized link field to OpenLibrary authors' do
      author_data = [
        { 'key' => '/authors/OL123A', 'name' => 'Test Author' }
      ]

      controller.instance_variable_set(:@authors, author_data)
      controller.send(:map_authors)

      authors = controller.instance_variable_get(:@authors)
      expect(authors[0]['link']).to eq('http://openlibrary.org/authors/OL123A')
    end

    it 'creates Person record for new authors' do
      author_data = [
        { 'key' => '/authors/OL456A', 'name' => 'New Author' }
      ]

      controller.instance_variable_set(:@authors, author_data)

      expect {
        controller.send(:map_authors)
      }.to change(Person, :count).by(1)

      person = Person.find_by_openlibrary_id('/authors/OL456A')
      expect(person).to be_present
      expect(person.name).to eq('New Author')
    end

    it 'reuses existing Person records' do
      existing_person = Person.create!(openlibrary_id: '/authors/OL789A', name: 'Existing Author')

      author_data = [
        { 'key' => '/authors/OL789A', 'name' => 'Existing Author' }
      ]

      controller.instance_variable_set(:@authors, author_data)

      expect {
        controller.send(:map_authors)
      }.not_to change(Person, :count)

      authors = controller.instance_variable_get(:@authors)
      expect(authors[0]['person']).to eq(existing_person)
    end
  end

  describe '#new_from_gutendex' do
    let(:gutendex_client) { instance_double(Gutendex::Client) }
    let(:book_data) do
      {
        'title' => 'Pride and Prejudice',
        'authors' => [
          { 'name' => 'Austen, Jane', 'birth_year' => 1775, 'death_year' => 1817 }
        ]
      }
    end

    before do
      allow(Gutendex::Client).to receive(:new).and_return(gutendex_client)
      allow(gutendex_client).to receive(:book).and_return(book_data)
      controller.instance_variable_set(:@toc, Toc.new)
    end

    it 'creates standardized author format with nil link for Gutenberg authors' do
      controller.send(:new_from_gutendex)

      authors = controller.instance_variable_get(:@authors)
      expect(authors).to be_present
      expect(authors[0]).to include(
        'name' => 'Austen, Jane',
        'birth_year' => 1775,
        'death_year' => 1817,
        'link' => nil
      )
    end

    it 'handles books with no authors' do
      book_data_no_authors = book_data.merge('authors' => nil)
      allow(gutendex_client).to receive(:book).and_return(book_data_no_authors)

      controller.send(:new_from_gutendex)

      authors = controller.instance_variable_get(:@authors)
      expect(authors).to eq([])
    end

    it 'creates Person records for Gutendex authors' do
      expect {
        controller.send(:new_from_gutendex)
      }.to change(Person, :count).by(1)

      person = Person.find_by(name: 'Austen, Jane')
      expect(person).to be_present
      expect(person.openlibrary_id).to be_nil
    end

    it 'reuses existing Person records for Gutendex authors' do
      existing_person = Person.create!(name: 'Austen, Jane')

      expect {
        controller.send(:new_from_gutendex)
      }.not_to change(Person, :count)

      authors = controller.instance_variable_get(:@authors)
      expect(authors[0]['person']).to eq(existing_person)
    end

    it 'adds person reference to Gutendex authors' do
      controller.send(:new_from_gutendex)

      authors = controller.instance_variable_get(:@authors)
      expect(authors[0]['person']).to be_a(Person)
      expect(authors[0]['person'].name).to eq('Austen, Jane')
    end
  end

  describe '#get_authors' do
    context 'with Open Library URI' do
      let(:book_data) { { 'title' => 'Test Book', 'authors' => [{ 'key' => '/authors/OL123A' }] } }
      let(:author_data) { { 'key' => '/authors/OL123A', 'name' => 'Test Author' } }

      before do
        allow(controller).to receive(:rest_get).with('http://openlibrary.org/books/OL1M.json').and_return(book_data)
        allow(controller).to receive(:rest_get).with('http://openlibrary.org/authors/OL123A.json').and_return(author_data)
      end

      it 'fetches book and author data from Open Library' do
        controller.send(:get_authors, 'http://openlibrary.org/books/OL1M')

        book = controller.instance_variable_get(:@book)
        authors = controller.instance_variable_get(:@authors)

        expect(book).to eq(book_data)
        expect(authors).to be_present
        expect(authors[0]['name']).to eq('Test Author')
      end

      it 'creates Person records for Open Library authors' do
        expect {
          controller.send(:get_authors, 'http://openlibrary.org/books/OL1M')
        }.to change(Person, :count).by(1)

        person = Person.find_by_openlibrary_id('/authors/OL123A')
        expect(person).to be_present
        expect(person.name).to eq('Test Author')
      end
    end

    context 'with Gutenberg URI and source: gutenberg (regression test for JSON::ParserError)' do
      let(:gutendex_client) { instance_double(Gutendex::Client) }
      let(:gutendex_book_data) do
        {
          'title' => 'Pride and Prejudice',
          'authors' => [
            { 'name' => 'Austen, Jane', 'birth_year' => 1775, 'death_year' => 1817 }
          ]
        }
      end

      before do
        # Create a Gutenberg TOC with source set but no book_data
        gutenberg_toc = Toc.new(
          book_uri: 'https://www.gutenberg.org/ebooks/1342',
          title: 'Pride and Prejudice',
          source: :gutenberg,
          book_data: nil  # This is the problematic scenario
        )
        controller.instance_variable_set(:@toc, gutenberg_toc)

        allow(Gutendex::Client).to receive(:new).and_return(gutendex_client)
        allow(gutendex_client).to receive(:book).with('1342').and_return(gutendex_book_data)
      end

      it 'handles Gutenberg URI when source is gutenberg but book_data is nil' do
        # This should NOT raise JSON::ParserError
        # It should fetch the book data from Gutendex instead
        expect {
          controller.send(:get_authors, 'https://www.gutenberg.org/ebooks/1342')
        }.not_to raise_error

        authors = controller.instance_variable_get(:@authors)
        expect(authors).to be_present
        expect(authors[0]['name']).to eq('Austen, Jane')
      end

      it 'fetches book data from Gutendex when given a Gutenberg URI' do
        controller.send(:get_authors, 'https://www.gutenberg.org/ebooks/1342')

        expect(gutendex_client).to have_received(:book).with('1342')

        book = controller.instance_variable_get(:@book)
        expect(book).to eq(gutendex_book_data)
      end
    end

    context 'with Gutendex book data' do
      let(:gutendex_book_data) do
        {
          'title' => 'Pride and Prejudice',
          'authors' => [
            { 'name' => 'Austen, Jane', 'birth_year' => 1775, 'death_year' => 1817 }
          ]
        }
      end

      it 'processes Gutendex book data directly' do
        controller.send(:get_authors, gutendex_book_data)

        book = controller.instance_variable_get(:@book)
        authors = controller.instance_variable_get(:@authors)

        expect(book).to eq(gutendex_book_data)
        expect(authors).to be_present
        expect(authors[0]['name']).to eq('Austen, Jane')
        expect(authors[0]['birth_year']).to eq(1775)
        expect(authors[0]['death_year']).to eq(1817)
      end

      it 'creates Person records for Gutendex authors' do
        expect {
          controller.send(:get_authors, gutendex_book_data)
        }.to change(Person, :count).by(1)

        person = Person.find_by(name: 'Austen, Jane')
        expect(person).to be_present
        expect(person.openlibrary_id).to be_nil
      end

      it 'adds person reference to Gutendex authors' do
        controller.send(:get_authors, gutendex_book_data)

        authors = controller.instance_variable_get(:@authors)
        expect(authors[0]['person']).to be_a(Person)
        expect(authors[0]['person'].name).to eq('Austen, Jane')
        expect(authors[0]['link']).to be_nil
      end

      it 'handles books with no authors' do
        book_data_no_authors = gutendex_book_data.merge('authors' => nil)

        controller.send(:get_authors, book_data_no_authors)

        authors = controller.instance_variable_get(:@authors)
        expect(authors).to eq([])
      end
    end

    context 'when Open Library server returns error' do
      before do
        controller.instance_variable_set(:@toc, Toc.new(book_uri: 'http://openlibrary.org/books/OL1M'))
      end

      it 'handles 500 Internal Server Error gracefully' do
        allow(controller).to receive(:rest_get).and_raise(RestClient::InternalServerError.new('Server error'))

        controller.send(:get_authors, 'http://openlibrary.org/books/OL1M')

        authors = controller.instance_variable_get(:@authors)
        book = controller.instance_variable_get(:@book)

        expect(authors).to eq([])
        expect(book).to eq({})
        expect(flash.now[:warning]).to eq('Unable to fetch author information from Open Library. The service may be temporarily unavailable. You can still edit and save the TOC.')
      end

      it 'handles 503 Service Unavailable gracefully' do
        allow(controller).to receive(:rest_get).and_raise(RestClient::ServiceUnavailable.new('Service unavailable'))

        controller.send(:get_authors, 'http://openlibrary.org/books/OL1M')

        authors = controller.instance_variable_get(:@authors)
        expect(authors).to eq([])
        expect(flash.now[:warning]).to be_present
      end

      it 'handles network timeout errors gracefully' do
        allow(controller).to receive(:rest_get).and_raise(Timeout::Error.new('Request timeout'))

        controller.send(:get_authors, 'http://openlibrary.org/books/OL1M')

        authors = controller.instance_variable_get(:@authors)
        expect(authors).to eq([])
        expect(flash.now[:warning]).to be_present
      end

      it 'handles connection refused errors gracefully' do
        allow(controller).to receive(:rest_get).and_raise(Errno::ECONNREFUSED.new('Connection refused'))

        controller.send(:get_authors, 'http://openlibrary.org/books/OL1M')

        authors = controller.instance_variable_get(:@authors)
        expect(authors).to eq([])
        expect(flash.now[:warning]).to be_present
      end

      it 'handles socket errors gracefully' do
        allow(controller).to receive(:rest_get).and_raise(SocketError.new('Connection failed'))

        controller.send(:get_authors, 'http://openlibrary.org/books/OL1M')

        authors = controller.instance_variable_get(:@authors)
        expect(authors).to eq([])
        expect(flash.now[:warning]).to be_present
      end

      it 'handles JSON parsing errors gracefully' do
        allow(controller).to receive(:rest_get).and_raise(JSON::ParserError.new('Invalid JSON'))

        controller.send(:get_authors, 'http://openlibrary.org/books/OL1M')

        authors = controller.instance_variable_get(:@authors)
        expect(authors).to eq([])
        expect(flash.now[:warning]).to be_present
      end

      it 'logs the error for debugging' do
        allow(controller).to receive(:rest_get).and_raise(RestClient::InternalServerError.new('Server error'))
        allow(Rails.logger).to receive(:error)

        controller.send(:get_authors, 'http://openlibrary.org/books/OL1M')

        expect(Rails.logger).to have_received(:error).with(/Failed to fetch author information from Open Library/)
      end

      it 'does not call map_authors when error occurs' do
        allow(controller).to receive(:rest_get).and_raise(RestClient::InternalServerError.new('Server error'))
        allow(controller).to receive(:map_authors)

        controller.send(:get_authors, 'http://openlibrary.org/books/OL1M')

        expect(controller).not_to have_received(:map_authors)
      end
    end

    context 'when Open Library server is down during edit action' do
      let(:ol_toc) do
        Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL123M',
          title: 'Open Library Book'
        )
      end

      before do
        allow(controller).to receive(:rest_get).and_raise(RestClient::InternalServerError.new('Server error'))
      end

      it 'allows edit page to load with warning' do
        get :edit, params: { id: ol_toc.id }

        expect(response).to have_http_status(:success)
        expect(assigns(:authors)).to eq([])
        expect(flash.now[:warning]).to be_present
      end

      it 'sets @is_gutenberg to false for Open Library books even when error occurs' do
        get :edit, params: { id: ol_toc.id }

        expect(assigns(:is_gutenberg)).to eq(false)
      end
    end
  end

  describe '#map_authors - generalized for both sources' do
    context 'with Gutendex authors (no key field)' do
      it 'creates Person records by name for new Gutendex authors' do
        gutendex_authors = [
          { 'name' => 'Twain, Mark', 'birth_year' => 1835, 'death_year' => 1910 }
        ]
        controller.instance_variable_set(:@authors, gutendex_authors)

        expect {
          controller.send(:map_authors)
        }.to change(Person, :count).by(1)

        person = Person.find_by(name: 'Twain, Mark')
        expect(person).to be_present
        expect(person.openlibrary_id).to be_nil
      end

      it 'reuses existing Person records for Gutendex authors' do
        existing_person = Person.create!(name: 'Dickens, Charles')
        gutendex_authors = [
          { 'name' => 'Dickens, Charles', 'birth_year' => 1812, 'death_year' => 1870 }
        ]
        controller.instance_variable_set(:@authors, gutendex_authors)

        expect {
          controller.send(:map_authors)
        }.not_to change(Person, :count)

        authors = controller.instance_variable_get(:@authors)
        expect(authors[0]['person']).to eq(existing_person)
      end

      it 'sets link to nil for Gutendex authors' do
        gutendex_authors = [
          { 'name' => 'Shelley, Mary', 'birth_year' => 1797, 'death_year' => 1851 }
        ]
        controller.instance_variable_set(:@authors, gutendex_authors)

        controller.send(:map_authors)

        authors = controller.instance_variable_get(:@authors)
        expect(authors[0]['link']).to be_nil
      end
    end

    context 'with Open Library authors (has key field)' do
      it 'creates Person records by openlibrary_id for new authors' do
        ol_authors = [
          { 'key' => '/authors/OL999A', 'name' => 'New OL Author' }
        ]
        controller.instance_variable_set(:@authors, ol_authors)

        expect {
          controller.send(:map_authors)
        }.to change(Person, :count).by(1)

        person = Person.find_by_openlibrary_id('/authors/OL999A')
        expect(person).to be_present
        expect(person.name).to eq('New OL Author')
      end

      it 'sets link for Open Library authors' do
        ol_authors = [
          { 'key' => '/authors/OL888A', 'name' => 'OL Author' }
        ]
        controller.instance_variable_set(:@authors, ol_authors)

        controller.send(:map_authors)

        authors = controller.instance_variable_get(:@authors)
        expect(authors[0]['link']).to eq('http://openlibrary.org/authors/OL888A')
      end
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

  describe 'POST #auto_match_subjects' do
    let(:work) { Work.create!(title: 'Test Work') }
    let(:expression) { Expression.create!(work: work, title: 'Test Expression') }
    let(:manifestation) { Manifestation.create! }
    let!(:main_embodiment) { Embodiment.create!(expression: expression, manifestation: manifestation, sequence_number: nil) }
    let(:processed_toc) do
      # Create manifestation and embodiment first
      main_embodiment # Force creation
      toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book',
        imported_subjects: "Fiction\nScience Fiction\nHistorical Fiction",
        manifestation: manifestation
      )
      toc
    end

    let(:lc_client) { instance_double(LibraryOfCongress::Client) }

    before do
      allow(LibraryOfCongress::Client).to receive(:new).and_return(lc_client)
      # Default stub to return empty array for any subject
      allow(lc_client).to receive(:search_subjects).and_return([])
      # Stub find_exact_match even though it shouldn't be called (for spy to work)
      allow(lc_client).to receive(:find_exact_match).and_return(nil)
    end

    it 'calls search_subjects only once per subject (not twice)' do
      fiction_results = [
        { uri: 'http://id.loc.gov/authorities/subjects/sh85048050', label: 'Fiction' }
      ]
      sf_results = [
        { uri: 'http://id.loc.gov/authorities/subjects/sh85048051', label: 'Science Fiction' }
      ]
      hf_results = [
        { uri: 'http://id.loc.gov/authorities/subjects/sh85048052', label: 'Historical Fiction' }
      ]

      # Mock search_subjects to return different results for each subject
      allow(lc_client).to receive(:search_subjects).with('Fiction').and_return(fiction_results)
      allow(lc_client).to receive(:search_subjects).with('Science Fiction').and_return(sf_results)
      allow(lc_client).to receive(:search_subjects).with('Historical Fiction').and_return(hf_results)

      post :auto_match_subjects, params: { id: processed_toc.id }, format: :js

      # Verify search_subjects was called exactly once per subject
      expect(lc_client).to have_received(:search_subjects).with('Fiction').once
      expect(lc_client).to have_received(:search_subjects).with('Science Fiction').once
      expect(lc_client).to have_received(:search_subjects).with('Historical Fiction').once

      # Verify find_exact_match was NOT called
      expect(lc_client).not_to have_received(:find_exact_match)
    end

    it 'creates Aboutness for exact matches found in search results' do
      fiction_results = [
        { uri: 'http://id.loc.gov/authorities/subjects/sh85048050', label: 'Fiction' }
      ]

      allow(lc_client).to receive(:search_subjects).with('Fiction').and_return(fiction_results)

      # Mock Wikidata client to return no mapping (so only LCSH is created)
      wikidata_client = instance_double(SubjectHeadings::WikidataClient)
      allow(SubjectHeadings::WikidataClient).to receive(:new).and_return(wikidata_client)
      allow(wikidata_client).to receive(:find_entity_by_library_of_congress_id).with('sh85048050').and_return(nil)

      expect {
        post :auto_match_subjects, params: { id: processed_toc.id }, format: :js
      }.to change(Aboutness, :count).by(1)

      aboutness = Aboutness.last
      expect(aboutness.embodiment).to eq(main_embodiment)
      expect(aboutness.subject_heading_uri).to eq('http://id.loc.gov/authorities/subjects/sh85048050')
      expect(aboutness.subject_heading_label).to eq('Fiction')
      expect(aboutness.source_name).to eq('LCSH')
    end

    it 'shows all matches as suggestions (not just top 3)' do
      # Create 10 results to test that all are shown
      many_results = (1..10).map do |i|
        { uri: "http://id.loc.gov/authorities/subjects/sh8504805#{i}", label: "Fiction variant #{i}" }
      end

      allow(lc_client).to receive(:search_subjects).with('Fiction').and_return(many_results)

      post :auto_match_subjects, params: { id: processed_toc.id }, format: :js

      suggestions = assigns(:suggestions)
      expect(suggestions).to be_present
      expect(suggestions.first[:matches].length).to eq(10) # All 10, not just 3
    end

    it 'handles subjects with no matches' do
      allow(lc_client).to receive(:search_subjects).with('Fiction').and_return([])
      allow(lc_client).to receive(:search_subjects).with('Science Fiction').and_return([])
      allow(lc_client).to receive(:search_subjects).with('Historical Fiction').and_return([])

      post :auto_match_subjects, params: { id: processed_toc.id }, format: :js

      expect(assigns(:exact_matches)).to be_empty
      expect(assigns(:suggestions)).to be_empty

      # All subjects should remain in imported_subjects
      processed_toc.reload
      expect(processed_toc.imported_subjects).to include('Fiction')
      expect(processed_toc.imported_subjects).to include('Science Fiction')
      expect(processed_toc.imported_subjects).to include('Historical Fiction')
    end

    it 'removes exact matches from imported_subjects' do
      fiction_results = [
        { uri: 'http://id.loc.gov/authorities/subjects/sh85048050', label: 'Fiction' }
      ]
      sf_results = [
        { uri: 'http://id.loc.gov/authorities/subjects/sh85048051', label: 'Science Fiction' }
      ]

      allow(lc_client).to receive(:search_subjects).with('Fiction').and_return(fiction_results)
      allow(lc_client).to receive(:search_subjects).with('Science Fiction').and_return(sf_results)
      allow(lc_client).to receive(:search_subjects).with('Historical Fiction').and_return([
        { uri: 'http://id.loc.gov/authorities/subjects/sh85048099', label: 'Some other fiction' }
      ])

      post :auto_match_subjects, params: { id: processed_toc.id }, format: :js

      processed_toc.reload
      remaining = processed_toc.imported_subjects.split("\n").map(&:strip)
      # Fiction and Science Fiction should be removed (exact matches)
      expect(remaining).not_to include('Fiction')
      expect(remaining).not_to include('Science Fiction')
      # Historical Fiction should remain (no exact match)
      expect(remaining).to include('Historical Fiction')
    end

    it 'is case-insensitive when matching' do
      fiction_results = [
        { uri: 'http://id.loc.gov/authorities/subjects/sh85048050', label: 'fiction' } # lowercase
      ]

      allow(lc_client).to receive(:search_subjects).with('Fiction').and_return(fiction_results)

      post :auto_match_subjects, params: { id: processed_toc.id }, format: :js

      # Should recognize 'fiction' as an exact match for 'Fiction'
      expect(assigns(:exact_matches).length).to eq(1)
      expect(assigns(:exact_matches).first[:matched_label]).to eq('fiction')
    end

    it 'shows error when TOC has not been processed' do
      unprocessed_toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL999M',
        title: 'Unprocessed',
        imported_subjects: 'Fiction'
      )

      post :auto_match_subjects, params: { id: unprocessed_toc.id }, format: :js

      expect(assigns(:error)).to eq('TOC must be processed first before auto-matching subjects')
      expect(assigns(:exact_matches)).to be_empty
      expect(assigns(:suggestions)).to be_empty
    end

    it 'auto-adds equivalent Wikidata aboutness when LCSH exact match has Wikidata mapping' do
      # Create a TOC with Mathematics as the subject
      math_toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL456M',
        title: 'Math Book',
        imported_subjects: 'Mathematics',
        manifestation: manifestation
      )

      # Mock LC search to return an exact match with sh85082139 (Mathematics)
      lc_results = [
        { uri: 'https://id.loc.gov/authorities/subjects/sh85082139', label: 'Mathematics' }
      ]
      allow(lc_client).to receive(:search_subjects).with('Mathematics').and_return(lc_results)

      # Mock Wikidata client to return Q395 (mathematics)
      wikidata_client = instance_double(SubjectHeadings::WikidataClient)
      allow(SubjectHeadings::WikidataClient).to receive(:new).and_return(wikidata_client)
      allow(wikidata_client).to receive(:find_entity_by_library_of_congress_id).with('sh85082139').and_return(
        { entity_id: 'Q395', label: 'mathematics' }
      )

      # Should create both LCSH and Wikidata aboutnesses
      expect {
        post :auto_match_subjects, params: { id: math_toc.id }, format: :js
      }.to change(Aboutness, :count).by(2)

      # Check LCSH aboutness
      lcsh_aboutness = Aboutness.find_by(source_name: 'LCSH', subject_heading_uri: 'https://id.loc.gov/authorities/subjects/sh85082139')
      expect(lcsh_aboutness).to be_present
      expect(lcsh_aboutness.subject_heading_label).to eq('Mathematics')
      expect(lcsh_aboutness.status).to eq('verified')
      expect(lcsh_aboutness.contributor_id).to be_nil
      expect(lcsh_aboutness.embodiment).to eq(main_embodiment)

      # Check Wikidata aboutness
      wikidata_aboutness = Aboutness.find_by(source_name: 'Wikidata', subject_heading_uri: 'http://www.wikidata.org/entity/Q395')
      expect(wikidata_aboutness).to be_present
      expect(wikidata_aboutness.subject_heading_label).to eq('mathematics')
      expect(wikidata_aboutness.status).to eq('verified')
      expect(wikidata_aboutness.contributor_id).to be_nil
      expect(wikidata_aboutness.embodiment).to eq(main_embodiment)
    end

    it 'handles cases where LCSH match has no Wikidata equivalent' do
      # Create a TOC with Obscure Topic as the subject
      obscure_toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL789M',
        title: 'Obscure Book',
        imported_subjects: 'Obscure Topic',
        manifestation: manifestation
      )

      # Mock LC search to return an exact match
      lc_results = [
        { uri: 'https://id.loc.gov/authorities/subjects/sh99999999', label: 'Obscure Topic' }
      ]
      allow(lc_client).to receive(:search_subjects).with('Obscure Topic').and_return(lc_results)

      # Mock Wikidata client to return nil (no Wikidata mapping)
      wikidata_client = instance_double(SubjectHeadings::WikidataClient)
      allow(SubjectHeadings::WikidataClient).to receive(:new).and_return(wikidata_client)
      allow(wikidata_client).to receive(:find_entity_by_library_of_congress_id).with('sh99999999').and_return(nil)

      # Should only create LCSH aboutness (not Wikidata)
      expect {
        post :auto_match_subjects, params: { id: obscure_toc.id }, format: :js
      }.to change(Aboutness, :count).by(1)

      # Check only LCSH aboutness was created
      lcsh_aboutness = Aboutness.last
      expect(lcsh_aboutness.source_name).to eq('LCSH')
      expect(lcsh_aboutness.subject_heading_uri).to eq('https://id.loc.gov/authorities/subjects/sh99999999')
    end

    it 'does not create duplicate Wikidata aboutness if it already exists' do
      # Create a TOC with Mathematics as the subject
      math_toc2 = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL999M',
        title: 'Another Math Book',
        imported_subjects: 'Mathematics',
        manifestation: manifestation
      )

      # Mock LC search
      lc_results = [
        { uri: 'https://id.loc.gov/authorities/subjects/sh85082139', label: 'Mathematics' }
      ]
      allow(lc_client).to receive(:search_subjects).with('Mathematics').and_return(lc_results)

      # Mock Wikidata client
      wikidata_client = instance_double(SubjectHeadings::WikidataClient)
      allow(SubjectHeadings::WikidataClient).to receive(:new).and_return(wikidata_client)
      allow(wikidata_client).to receive(:find_entity_by_library_of_congress_id).with('sh85082139').and_return(
        { entity_id: 'Q395', label: 'mathematics' }
      )

      # Pre-create Wikidata aboutness
      Aboutness.create!(
        embodiment: main_embodiment,
        subject_heading_uri: 'http://www.wikidata.org/entity/Q395',
        source_name: 'Wikidata',
        subject_heading_label: 'mathematics',
        status: 'verified',
        contributor_id: nil
      )

      # Should only create LCSH aboutness (Wikidata already exists)
      expect {
        post :auto_match_subjects, params: { id: math_toc2.id }, format: :js
      }.to change(Aboutness, :count).by(1)

      # Verify only one Wikidata aboutness exists
      wikidata_count = Aboutness.where(source_name: 'Wikidata', subject_heading_uri: 'http://www.wikidata.org/entity/Q395').count
      expect(wikidata_count).to eq(1)
    end
  end

  describe 'GET #edit' do
    context 'with Gutendex book_data stored' do
      let(:gutendex_client) { instance_double(Gutendex::Client) }
      let(:gutendex_book_data) do
        {
          'title' => 'Pride and Prejudice',
          'authors' => [
            { 'name' => 'Austen, Jane', 'birth_year' => 1775, 'death_year' => 1817 }
          ]
        }
      end
      let(:gutendex_toc) do
        Toc.create!(
          book_uri: 'https://www.gutenberg.org/ebooks/1342',
          title: 'Pride and Prejudice',
          book_data: gutendex_book_data
        )
      end

      before do
        allow(Gutendex::Client).to receive(:new).and_return(gutendex_client)
        allow(gutendex_client).to receive(:preferred_fulltext_url).with('1342').and_return('https://www.gutenberg.org/files/1342/1342-h/1342-h.htm')
      end

      it 'uses stored book_data instead of making network request' do
        # Should NOT call rest_get since we have book_data
        expect(controller).not_to receive(:rest_get)

        get :edit, params: { id: gutendex_toc.id }

        expect(response).to have_http_status(:success)
        authors = controller.instance_variable_get(:@authors)
        expect(authors).to be_present
        expect(authors[0]['name']).to eq('Austen, Jane')
      end

      it 'populates @book and @authors from stored book_data' do
        get :edit, params: { id: gutendex_toc.id }

        book = controller.instance_variable_get(:@book)
        authors = controller.instance_variable_get(:@authors)

        expect(book).to eq(gutendex_book_data)
        expect(authors[0]['name']).to eq('Austen, Jane')
        expect(authors[0]['birth_year']).to eq(1775)
      end
    end

    context 'with Open Library book_uri (no book_data)' do
      let(:ol_toc) do
        Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL123M',
          title: 'Open Library Book'
        )
      end
      let(:book_data) { { 'title' => 'Open Library Book', 'authors' => [{ 'key' => '/authors/OL123A' }] } }
      let(:author_data) { { 'key' => '/authors/OL123A', 'name' => 'Test Author' } }

      before do
        allow(controller).to receive(:rest_get).with('http://openlibrary.org/books/OL123M.json').and_return(book_data)
        allow(controller).to receive(:rest_get).with('http://openlibrary.org/authors/OL123A.json').and_return(author_data)
      end

      it 'fetches book and author data from book_uri' do
        expect(controller).to receive(:rest_get).with('http://openlibrary.org/books/OL123M.json')
        expect(controller).to receive(:rest_get).with('http://openlibrary.org/authors/OL123A.json')

        get :edit, params: { id: ol_toc.id }

        expect(response).to have_http_status(:success)
        authors = controller.instance_variable_get(:@authors)
        expect(authors).to be_present
        expect(authors[0]['name']).to eq('Test Author')
      end

      it 'sets @is_gutenberg to false for Open Library books' do
        get :edit, params: { id: ol_toc.id }

        expect(assigns(:is_gutenberg)).to eq(false)
        expect(assigns(:fulltext_url)).to be_nil
      end
    end

    context 'with Project Gutenberg book_uri' do
      let(:gutendex_client) { instance_double(Gutendex::Client) }
      let(:fulltext_url) { 'https://www.gutenberg.org/files/84/84-h/84-h.htm' }
      let(:gutenberg_toc) do
        Toc.create!(
          book_uri: 'https://www.gutenberg.org/ebooks/84',
          title: 'Frankenstein',
          book_data: {
            'title' => 'Frankenstein',
            'authors' => [{ 'name' => 'Shelley, Mary Wollstonecraft', 'birth_year' => 1797, 'death_year' => 1851 }]
          }
        )
      end

      before do
        allow(Gutendex::Client).to receive(:new).and_return(gutendex_client)
        allow(gutendex_client).to receive(:preferred_fulltext_url).with('84').and_return(fulltext_url)
      end

      it 'sets @is_gutenberg to true and fetches fulltext URL' do
        get :edit, params: { id: gutenberg_toc.id }

        expect(assigns(:is_gutenberg)).to eq(true)
        expect(assigns(:fulltext_url)).to eq(fulltext_url)
        expect(gutendex_client).to have_received(:preferred_fulltext_url).with('84')
      end
    end
  end

  describe '#store_authors' do
    let(:toc) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL123M', title: 'Test Book') }
    let(:person1) { Person.create!(name: 'Author One') }
    let(:person2) { Person.create!(name: 'Author Two') }

    before do
      controller.instance_variable_set(:@toc, toc)
    end

    it 'creates PeopleToc records for each author' do
      authors = [
        { 'name' => 'Author One', 'person' => person1 },
        { 'name' => 'Author Two', 'person' => person2 }
      ]
      controller.instance_variable_set(:@authors, authors)

      expect {
        controller.send(:store_authors)
      }.to change(PeopleToc, :count).by(2)

      expect(toc.authors).to include(person1)
      expect(toc.authors).to include(person2)
    end

    it 'clears existing authors before adding new ones' do
      PeopleToc.create!(person: person1, toc: toc)
      expect(toc.authors.count).to eq(1)

      authors = [
        { 'name' => 'Author Two', 'person' => person2 }
      ]
      controller.instance_variable_set(:@authors, authors)

      controller.send(:store_authors)

      expect(toc.authors.count).to eq(1)
      expect(toc.authors).not_to include(person1)
      expect(toc.authors).to include(person2)
    end

    it 'skips authors with nil person' do
      authors = [
        { 'name' => 'Author One', 'person' => person1 },
        { 'name' => 'Unknown Author', 'person' => nil }
      ]
      controller.instance_variable_set(:@authors, authors)

      expect {
        controller.send(:store_authors)
      }.to change(PeopleToc, :count).by(1)

      expect(toc.authors).to include(person1)
      expect(toc.authors.count).to eq(1)
    end

    it 'does nothing if @authors is blank' do
      controller.instance_variable_set(:@authors, [])

      expect {
        controller.send(:store_authors)
      }.not_to change(PeopleToc, :count)
    end

    it 'does nothing if @toc is nil' do
      controller.instance_variable_set(:@toc, nil)
      authors = [{ 'name' => 'Author One', 'person' => person1 }]
      controller.instance_variable_set(:@authors, authors)

      expect {
        controller.send(:store_authors)
      }.not_to change(PeopleToc, :count)
    end
  end

  describe 'POST #create' do
    let(:book_data) { { 'title' => 'Test Book', 'authors' => [{ 'key' => '/authors/OL123A' }] } }
    let(:author_data) { { 'key' => '/authors/OL123A', 'name' => 'Test Author' } }

    before do
      allow(controller).to receive(:rest_get).with('http://openlibrary.org/books/OL123M.json').and_return(book_data)
      allow(controller).to receive(:rest_get).with('http://openlibrary.org/authors/OL123A.json').and_return(author_data)
    end

    it 'stores authors when creating a TOC with book_uri' do
      toc_params = {
        title: 'Test Book',
        book_uri: 'http://openlibrary.org/books/OL123M'
      }

      expect {
        post :create, params: { toc: toc_params }
      }.to change(PeopleToc, :count).by(1)

      toc = Toc.last
      expect(toc.authors.count).to eq(1)
      expect(toc.authors.first.name).to eq('Test Author')
    end
  end

  describe 'PATCH #update' do
    let(:toc) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL123M', title: 'Original Title') }
    let(:book_data) { { 'title' => 'Test Book', 'authors' => [{ 'key' => '/authors/OL123A' }] } }
    let(:author_data) { { 'key' => '/authors/OL123A', 'name' => 'Test Author' } }

    before do
      allow(controller).to receive(:rest_get).with('http://openlibrary.org/books/OL123M.json').and_return(book_data)
      allow(controller).to receive(:rest_get).with('http://openlibrary.org/authors/OL123A.json').and_return(author_data)
    end

    it 'updates and stores authors when updating a TOC' do
      expect {
        patch :update, params: { id: toc.id, toc: { title: 'Updated Title' } }
      }.to change(PeopleToc, :count).by(1)

      toc.reload
      expect(toc.title).to eq('Updated Title')
      expect(toc.authors.count).to eq(1)
      expect(toc.authors.first.name).to eq('Test Author')
    end

    it 'replaces existing authors when updating' do
      old_person = Person.create!(name: 'Old Author')
      PeopleToc.create!(person: old_person, toc: toc)

      patch :update, params: { id: toc.id, toc: { title: 'Updated Title' } }

      toc.reload
      expect(toc.authors.count).to eq(1)
      expect(toc.authors).not_to include(old_person)
      expect(toc.authors.first.name).to eq('Test Author')
    end
  end

  describe 'OCR environment variable configuration' do
    describe '#get_ocr_from_service' do
      it 'uses OCR_METHOD environment variable to select tesseract' do
        allow(ENV).to receive(:fetch).with('OCR_METHOD', 'tesseract').and_return('tesseract')
        allow(controller).to receive(:get_ocr_with_tesseract).and_return('tesseract result')

        result = controller.send(:get_ocr_from_service, 'http://example.com/image.jpg')

        expect(controller).to have_received(:get_ocr_with_tesseract)
        expect(result).to eq('tesseract result')
      end

      it 'uses OCR_METHOD environment variable to select rest API' do
        allow(ENV).to receive(:fetch).with('OCR_METHOD', 'tesseract').and_return('rest')
        allow(controller).to receive(:get_ocr_with_rest_api).and_return('rest result')

        result = controller.send(:get_ocr_from_service, 'http://example.com/image.jpg')

        expect(controller).to have_received(:get_ocr_with_rest_api)
        expect(result).to eq('rest result')
      end

      it 'defaults to tesseract when OCR_METHOD is not set' do
        allow(ENV).to receive(:fetch).with('OCR_METHOD', 'tesseract').and_call_original
        allow(controller).to receive(:get_ocr_with_tesseract).and_return('default result')

        result = controller.send(:get_ocr_from_service, 'http://example.com/image.jpg')

        expect(controller).to have_received(:get_ocr_with_tesseract)
        expect(result).to eq('default result')
      end
    end

    describe '#get_ocr_with_rest_api' do
      it 'uses OCR_SERVICE_URL environment variable' do
        allow(ENV).to receive(:[]).with('OCR_SERVICE_URL').and_return('http://custom-ocr-service.example')
        allow(HTTParty).to receive(:post).and_return(double(success?: true, body: '{"text": "OCR result"}', parsed_response: { 'text' => 'OCR result' }))

        controller.send(:get_ocr_with_rest_api, 'http://example.com/image.jpg')

        expect(HTTParty).to have_received(:post).with(
          'http://custom-ocr-service.example/ocr',
          hash_including(body: { url: 'http://example.com/image.jpg' }.to_json)
        )
      end

      it 'raises error when OCR_SERVICE_URL is not configured' do
        allow(ENV).to receive(:[]).with('OCR_SERVICE_URL').and_return(nil)

        expect {
          controller.send(:get_ocr_with_rest_api, 'http://example.com/image.jpg')
        }.to raise_error('OCR_SERVICE_URL not configured')
      end
    end
  end

  describe '#parse_toc_authors' do
    it 'parses single author' do
      title, authors = controller.send(:parse_toc_authors, 'Title || Author')
      expect(title).to eq('Title')
      expect(authors).to eq(['Author'])
    end

    it 'parses multiple authors separated by semicolon' do
      title, authors = controller.send(:parse_toc_authors, 'Title || Author1; Author2')
      expect(title).to eq('Title')
      expect(authors).to eq(['Author1', 'Author2'])
    end

    it 'handles three or more authors' do
      title, authors = controller.send(:parse_toc_authors, 'Title || Author1; Author2; Author3')
      expect(title).to eq('Title')
      expect(authors).to eq(['Author1', 'Author2', 'Author3'])
    end

    it 'handles no author' do
      title, authors = controller.send(:parse_toc_authors, 'Title')
      expect(title).to eq('Title')
      expect(authors).to eq([])
    end

    it 'strips whitespace from title and author names' do
      title, authors = controller.send(:parse_toc_authors, '  Title  ||  Author1  ;  Author2  ')
      expect(title).to eq('Title')
      expect(authors).to eq(['Author1', 'Author2'])
    end

    it 'filters out empty author names' do
      title, authors = controller.send(:parse_toc_authors, 'Title || Author1; ; Author2')
      expect(title).to eq('Title')
      expect(authors).to eq(['Author1', 'Author2'])
    end

    it 'handles empty author string after ||' do
      title, authors = controller.send(:parse_toc_authors, 'Title || ')
      expect(title).to eq('Title')
      expect(authors).to eq([])
    end
  end

  describe '#find_or_create_persons' do
    it 'creates new Person records for names that do not exist' do
      expect {
        persons = controller.send(:find_or_create_persons, ['New Author'])
        expect(persons.length).to eq(1)
        expect(persons.first.name).to eq('New Author')
      }.to change(Person, :count).by(1)
    end

    it 'reuses existing Person records for names that already exist' do
      existing_person = Person.create!(name: 'Existing Author')

      expect {
        persons = controller.send(:find_or_create_persons, ['Existing Author'])
        expect(persons.length).to eq(1)
        expect(persons.first).to eq(existing_person)
      }.not_to change(Person, :count)
    end

    it 'handles mix of new and existing authors' do
      existing_person = Person.create!(name: 'Existing')

      expect {
        persons = controller.send(:find_or_create_persons, ['Existing', 'New'])
        expect(persons.length).to eq(2)
        expect(persons.first).to eq(existing_person)
        expect(persons.last.name).to eq('New')
      }.to change(Person, :count).by(1)
    end

    it 'returns empty array for empty author names' do
      expect {
        persons = controller.send(:find_or_create_persons, [])
        expect(persons).to eq([])
      }.not_to change(Person, :count)
    end
  end

  describe '#link_authors_to_work' do
    it 'creates PeopleWork associations' do
      work = Work.create!(title: 'Test Work')
      person = Person.create!(name: 'Author')

      expect {
        controller.send(:link_authors_to_work, work, [person])
      }.to change(PeopleWork, :count).by(1)

      expect(work.creators).to include(person)
    end

    it 'links multiple persons to a work' do
      work = Work.create!(title: 'Test Work')
      person1 = Person.create!(name: 'Author1')
      person2 = Person.create!(name: 'Author2')

      expect {
        controller.send(:link_authors_to_work, work, [person1, person2])
      }.to change(PeopleWork, :count).by(2)

      expect(work.creators).to include(person1, person2)
    end

    it 'handles empty persons array gracefully' do
      work = Work.create!(title: 'Test Work')

      expect {
        controller.send(:link_authors_to_work, work, [])
      }.not_to change(PeopleWork, :count)
    end
  end

  describe '#process_toc with author associations' do
    let(:test_toc) { Toc.create!(book_uri: 'http://example.com/book', title: 'Test Collection') }

    before do
      controller.instance_variable_set(:@toc, test_toc)
    end

    context 'with explicit authors in TOC markdown' do
      it 'creates Person records and links to Works for single author' do
        markdown = "# Work 1 || Shakespeare"

        expect {
          controller.send(:process_toc, markdown)
        }.to change(Person, :count).by(1).and change(PeopleWork, :count).by(1)

        work = Work.find_by(title: 'Work 1')
        expect(work).not_to be_nil
        expect(work.creators.map(&:name)).to eq(['Shakespeare'])
      end

      it 'creates Person records and links to Works for multiple authors' do
        markdown = "# Work 1 || Author1; Author2"

        expect {
          controller.send(:process_toc, markdown)
        }.to change(Person, :count).by(2).and change(PeopleWork, :count).by(2)

        work = Work.find_by(title: 'Work 1')
        expect(work.creators.map(&:name)).to match_array(['Author1', 'Author2'])
      end

      it 'stores clean titles without author suffix' do
        markdown = "# Work Title || Author Name"

        controller.send(:process_toc, markdown)

        work = Work.find_by(title: 'Work Title')
        expect(work).not_to be_nil
        expect(work.title).to eq('Work Title')
        expect(work.title).not_to include('||')
      end

      it 'handles multiple works with different authors' do
        markdown = "# Work 1 || Author1\n# Work 2 || Author2"

        expect {
          controller.send(:process_toc, markdown)
        }.to change(Person, :count).by(2).and change(Work, :count).by(3) # 2 works + 1 aggregating

        work1 = Work.find_by(title: 'Work 1')
        work2 = Work.find_by(title: 'Work 2')
        expect(work1.creators.map(&:name)).to eq(['Author1'])
        expect(work2.creators.map(&:name)).to eq(['Author2'])
      end

      it 'reuses existing Person records with same name' do
        existing_person = Person.create!(name: 'Shared Author')
        markdown = "# Work 1 || Shared Author\n# Work 2 || Shared Author"

        expect {
          controller.send(:process_toc, markdown)
        }.to change(Person, :count).by(0).and change(PeopleWork, :count).by(2)

        work1 = Work.find_by(title: 'Work 1')
        work2 = Work.find_by(title: 'Work 2')
        expect(work1.creators.first).to eq(existing_person)
        expect(work2.creators.first).to eq(existing_person)
      end
    end

    context 'with fallback to book authors' do
      let(:book_author) { Person.create!(name: 'Book Author') }

      before do
        test_toc.authors << book_author
      end

      it 'links book authors to Works without explicit authors' do
        markdown = "# Work 1\n# Work 2"

        expect {
          controller.send(:process_toc, markdown)
        }.to change(PeopleWork, :count).by(2)

        work1 = Work.find_by(title: 'Work 1')
        work2 = Work.find_by(title: 'Work 2')
        expect(work1.creators).to include(book_author)
        expect(work2.creators).to include(book_author)
      end

      it 'uses explicit authors when present, book authors otherwise' do
        markdown = "# Work 1 || Explicit Author\n# Work 2"

        expect {
          controller.send(:process_toc, markdown)
        }.to change(Person, :count).by(1)

        work1 = Work.find_by(title: 'Work 1')
        work2 = Work.find_by(title: 'Work 2')
        expect(work1.creators.map(&:name)).to eq(['Explicit Author'])
        expect(work2.creators).to include(book_author)
      end
    end

    context 'with section headings' do
      it 'skips section headings ending with /' do
        markdown = "# Section Name /\n# Work 1 || Author"

        controller.send(:process_toc, markdown)

        # Should not create a Work for the section heading
        expect(Work.where(title: 'Section Name').count).to eq(0)
        expect(Work.where(title: 'Section Name /').count).to eq(0)

        # Should create Work for the actual entry
        work = Work.find_by(title: 'Work 1')
        expect(work).not_to be_nil
        expect(work.creators.map(&:name)).to eq(['Author'])
      end

      it 'handles multiple section headings' do
        markdown = "# Section 1 /\n# Work 1 || Author1\n# Section 2 /\n# Work 2 || Author2"

        controller.send(:process_toc, markdown)

        expect(Work.where('title LIKE ?', '%Section%').count).to eq(0)
        expect(Work.where(title: ['Work 1', 'Work 2']).count).to eq(2)
      end
    end

    context 'with nested works' do
      it 'assigns authors independently to nested works' do
        markdown = "# Work 1 || Author1\n## Nested Work || Author2"

        controller.send(:process_toc, markdown)

        work1 = Work.find_by(title: 'Work 1')
        nested_work = Work.find_by(title: 'Nested Work')
        expect(work1.creators.map(&:name)).to eq(['Author1'])
        expect(nested_work.creators.map(&:name)).to eq(['Author2'])
      end
    end

    context 'with no authors' do
      it 'creates Work with no creators when no explicit author and no book authors' do
        markdown = "# Work 1"

        controller.send(:process_toc, markdown)

        work = Work.find_by(title: 'Work 1')
        expect(work).not_to be_nil
        expect(work.creators).to be_empty
      end
    end
  end

  describe 'GET #gutenberg_proxy' do
    it 'proxies Gutenberg HTTPS URLs successfully' do
      url = 'https://www.gutenberg.org/files/84/84-h/84-h.htm'
      html_content = '<html><body>Frankenstein</body></html>'

      response_double = double(
        success?: true,
        body: html_content,
        headers: { 'content-type' => 'text/html; charset=utf-8' }
      )

      allow(HTTParty).to receive(:get).with(
        url,
        hash_including(follow_redirects: true)
      ).and_return(response_double)

      get :gutenberg_proxy, params: { url: url }

      expect(response).to have_http_status(:success)
      expect(response.body).to eq(html_content)
      expect(response.headers['Content-Type']).to include('text/html')
    end

    it 'converts HTTP URLs to HTTPS before fetching' do
      http_url = 'http://www.gutenberg.org/files/84/84-h/84-h.htm'
      https_url = 'https://www.gutenberg.org/files/84/84-h/84-h.htm'
      html_content = '<html><body>Test</body></html>'

      response_double = double(
        success?: true,
        body: html_content,
        headers: { 'content-type' => 'text/html' }
      )

      allow(HTTParty).to receive(:get).with(
        https_url,
        hash_including(follow_redirects: true)
      ).and_return(response_double)

      get :gutenberg_proxy, params: { url: http_url }

      expect(HTTParty).to have_received(:get).with(
        https_url,
        hash_including(follow_redirects: true)
      )
      expect(response).to have_http_status(:success)
    end

    it 'rejects non-Gutenberg URLs' do
      get :gutenberg_proxy, params: { url: 'https://evil.com/malware.html' }

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include('Only gutenberg.org URLs are allowed')
    end

    it 'handles HTTP errors from Gutenberg' do
      url = 'https://www.gutenberg.org/files/99999/not-found.htm'

      response_double = double(
        success?: false,
        code: 404
      )

      allow(HTTParty).to receive(:get).and_return(response_double)

      get :gutenberg_proxy, params: { url: url }

      expect(response).to have_http_status(:bad_gateway)
      expect(response.body).to include('Error fetching content: HTTP 404')
    end

    it 'handles network errors gracefully' do
      url = 'https://www.gutenberg.org/files/84/84-h/84-h.htm'

      allow(HTTParty).to receive(:get).and_raise(Timeout::Error.new('Request timeout'))

      get :gutenberg_proxy, params: { url: url }

      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include('Error: Request timeout')
    end

    it 'fixes HTTP links in HTML content' do
      url = 'https://www.gutenberg.org/files/84/84-h/84-h.htm'
      html_with_http_links = '<html><a href="http://www.gutenberg.org/other.html">Link</a></html>'
      expected_html = '<html><a href="https://www.gutenberg.org/other.html">Link</a></html>'

      response_double = double(
        success?: true,
        body: html_with_http_links,
        headers: { 'content-type' => 'text/html; charset=utf-8' }
      )

      allow(HTTParty).to receive(:get).and_return(response_double)

      get :gutenberg_proxy, params: { url: url }

      expect(response.body).to eq(expected_html)
    end

    it 'sets appropriate headers' do
      url = 'https://www.gutenberg.org/files/84/84-h/84-h.htm'
      html_content = '<html><body>Test</body></html>'

      response_double = double(
        success?: true,
        body: html_content,
        headers: { 'content-type' => 'text/html; charset=utf-8' }
      )

      allow(HTTParty).to receive(:get).and_return(response_double)

      get :gutenberg_proxy, params: { url: url }

      expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
      expect(response.headers['Content-Type']).to include('text/html')
    end

    it 'allows Gutenberg subdomains' do
      url = 'https://mirror.gutenberg.org/files/84/84-h.htm'
      html_content = '<html><body>Mirror</body></html>'

      response_double = double(
        success?: true,
        body: html_content,
        headers: { 'content-type' => 'text/html' }
      )

      allow(HTTParty).to receive(:get).and_return(response_double)

      get :gutenberg_proxy, params: { url: url }

      expect(response).to have_http_status(:success)
    end
  end

  describe '#fix_http_links_in_html' do
    it 'converts HTTP Gutenberg links to HTTPS' do
      html = '<a href="http://www.gutenberg.org/page.html">Link</a>'
      expected = '<a href="https://www.gutenberg.org/page.html">Link</a>'

      result = controller.send(:fix_http_links_in_html, html)

      expect(result).to eq(expected)
    end

    it 'leaves HTTPS Gutenberg links unchanged' do
      html = '<a href="https://www.gutenberg.org/page.html">Link</a>'

      result = controller.send(:fix_http_links_in_html, html)

      expect(result).to eq(html)
    end

    it 'handles multiple HTTP links' do
      html = '<a href="http://www.gutenberg.org/1.html">1</a><a href="http://www.gutenberg.org/2.html">2</a>'
      expected = '<a href="https://www.gutenberg.org/1.html">1</a><a href="https://www.gutenberg.org/2.html">2</a>'

      result = controller.send(:fix_http_links_in_html, html)

      expect(result).to eq(expected)
    end

    it 'handles Gutenberg URLs without www' do
      html = '<a href="http://gutenberg.org/page.html">Link</a>'
      expected = '<a href="https://gutenberg.org/page.html">Link</a>'

      result = controller.send(:fix_http_links_in_html, html)

      expect(result).to eq(expected)
    end

    it 'does not modify non-Gutenberg HTTP links' do
      html = '<a href="http://example.com/page.html">Link</a>'

      result = controller.send(:fix_http_links_in_html, html)

      expect(result).to eq(html)
    end
  end
end

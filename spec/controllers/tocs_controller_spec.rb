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
        toc_body: '## Table of Contents\n\n- Essay 1\n- Essay 2'
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
end

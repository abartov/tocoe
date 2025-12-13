require 'rails_helper'

RSpec.describe PublicTocsController, type: :controller do
  describe 'GET #index' do
    let!(:verified_toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL1M',
        title: 'Verified Book',
        status: :verified,
        toc_body: "# Chapter 1\n# Chapter 2"
      )
    end

    let!(:pages_marked_toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL2M',
        title: 'Pages Marked Book',
        status: :pages_marked
      )
    end

    let!(:transcribed_toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL3M',
        title: 'Transcribed Book',
        status: :transcribed
      )
    end

    it 'shows only verified TOCs' do
      get :index

      expect(assigns(:tocs)).to include(verified_toc)
      expect(assigns(:tocs)).not_to include(pages_marked_toc)
      expect(assigns(:tocs)).not_to include(transcribed_toc)
    end

    it 'allows unauthenticated access' do
      # Don't sign in
      get :index

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:index)
    end

    it 'applies default sorting (created_at desc)' do
      old_verified = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL4M',
        title: 'Old Verified',
        status: :verified,
        created_at: 2.days.ago
      )

      get :index

      tocs = assigns(:tocs).to_a
      expect(tocs.first).to eq(verified_toc)
      expect(tocs.last).to eq(old_verified)
    end

    it 'supports sorting by title ascending' do
      another_verified = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL5M',
        title: 'Aardvark Book',
        status: :verified
      )

      get :index, params: { sort: 'title', direction: 'asc' }

      tocs = assigns(:tocs).to_a
      expect(tocs.first).to eq(another_verified)
      expect(tocs.last).to eq(verified_toc)
    end

    it 'supports sorting by title descending' do
      another_verified = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL5M',
        title: 'Zebra Book',
        status: :verified
      )

      get :index, params: { sort: 'title', direction: 'desc' }

      tocs = assigns(:tocs).to_a
      expect(tocs.first).to eq(another_verified)
      expect(tocs.last).to eq(verified_toc)
    end

    it 'supports sorting by created_at ascending' do
      old_verified = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL4M',
        title: 'Old Verified',
        status: :verified,
        created_at: 2.days.ago
      )

      get :index, params: { sort: 'created_at', direction: 'asc' }

      tocs = assigns(:tocs).to_a
      expect(tocs.first).to eq(old_verified)
      expect(tocs.last).to eq(verified_toc)
    end

    it 'returns empty collection when no verified TOCs exist' do
      Toc.destroy_all

      get :index

      expect(assigns(:tocs)).to be_empty
    end
  end

  describe 'GET #show' do
    let!(:verified_toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL1M',
        title: 'Verified Book',
        status: :verified,
        toc_body: "# Chapter 1\n# Chapter 2"
      )
    end

    let!(:pending_toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL2M',
        title: 'Pending Book',
        status: :pages_marked
      )
    end

    it 'allows unauthenticated access to verified TOC' do
      get :show, params: { id: verified_toc.id }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
      expect(assigns(:toc)).to eq(verified_toc)
    end

    it 'returns 404 for non-verified TOC' do
      expect {
        get :show, params: { id: pending_toc.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns 404 for non-existent TOC' do
      expect {
        get :show, params: { id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'sets @manifestation if TOC has been processed' do
      manifestation = Manifestation.create!(title: 'Test Manifestation')
      verified_toc.update!(manifestation: manifestation)

      get :show, params: { id: verified_toc.id }

      expect(assigns(:manifestation)).to eq(manifestation)
    end

    context 'with Gutenberg book' do
      let!(:gutenberg_toc) do
        Toc.create!(
          book_uri: 'https://www.gutenberg.org/ebooks/12345',
          title: 'Gutenberg Book',
          status: :verified,
          source: :gutenberg
        )
      end

      it 'sets @is_gutenberg to true' do
        # Mock the Gutendex client
        gutendex_client = instance_double(Gutendex::Client)
        allow(Gutendex::Client).to receive(:new).and_return(gutendex_client)
        allow(gutendex_client).to receive(:preferred_fulltext_url).and_return('https://www.gutenberg.org/files/12345/12345-h/12345-h.htm')

        get :show, params: { id: gutenberg_toc.id }

        expect(assigns(:is_gutenberg)).to be true
        expect(assigns(:fulltext_url)).to eq('https://www.gutenberg.org/files/12345/12345-h/12345-h.htm')
      end
    end

    context 'with Open Library book' do
      it 'sets @is_gutenberg to false' do
        get :show, params: { id: verified_toc.id }

        expect(assigns(:is_gutenberg)).to be false
      end
    end
  end
end

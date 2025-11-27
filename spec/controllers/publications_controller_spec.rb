require 'rails_helper'

RSpec.describe PublicationsController, type: :controller do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

  # All tests run with authenticated user
  before do
    sign_in user
  end

  describe 'GET #search' do
    let(:mock_search_results) do
      {
        'numFound' => 3,
        'docs' => [
          {
            'title' => 'Book One',
            'author_name' => ['Author One'],
            'has_fulltext' => true,
            'ebook_access' => 'public',
            'editions' => {
              'docs' => [
                { 'key' => '/books/OL1M' }
              ]
            }
          },
          {
            'title' => 'Book Two',
            'author_name' => ['Author Two'],
            'has_fulltext' => true,
            'ebook_access' => 'public',
            'editions' => {
              'docs' => [
                { 'key' => '/books/OL2M' }
              ]
            }
          },
          {
            'title' => 'Book Three',
            'author_name' => ['Author Three'],
            'has_fulltext' => true,
            'ebook_access' => 'public',
            'editions' => {
              'docs' => [
                { 'key' => '/books/OL3M' }
              ]
            }
          }
        ]
      }
    end

    let(:mock_client) { instance_double(OpenLibrary::Client) }

    before do
      allow(controller).to receive(:olclient).and_return(mock_client)
      allow(mock_client).to receive(:search).and_return(mock_search_results)
    end

    context 'when filtering existing ToCs' do
      it 'removes publications that already have ToCs' do
        # Create a ToC for Book Two
        Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL2M',
          title: 'Book Two',
          status: :empty
        )

        get :search, params: { search: 'test' }

        results = assigns(:results)
        expect(results).to be_an(Array)
        expect(results.length).to eq(2)

        # Book Two should be filtered out
        titles = results.map { |r| r['title'] }
        expect(titles).to include('Book One')
        expect(titles).to include('Book Three')
        expect(titles).not_to include('Book Two')
      end

      it 'keeps all results when no ToCs exist' do
        get :search, params: { search: 'test' }

        results = assigns(:results)
        expect(results.length).to eq(3)

        titles = results.map { |r| r['title'] }
        expect(titles).to include('Book One')
        expect(titles).to include('Book Two')
        expect(titles).to include('Book Three')
      end

      it 'handles results without edition keys gracefully' do
        results_without_editions = {
          'numFound' => 1,
          'docs' => [
            {
              'title' => 'Book Without Edition',
              'author_name' => ['Author'],
              'has_fulltext' => false
            }
          ]
        }
        allow(mock_client).to receive(:search).and_return(results_without_editions)

        get :search, params: { search: 'test' }

        results = assigns(:results)
        expect(results.length).to eq(1)
        expect(results.first['title']).to eq('Book Without Edition')
      end

      it 'filters multiple existing ToCs correctly' do
        # Create ToCs for Book One and Book Three
        Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL1M',
          title: 'Book One',
          status: :empty
        )
        Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL3M',
          title: 'Book Three',
          status: :verified
        )

        get :search, params: { search: 'test' }

        results = assigns(:results)
        expect(results.length).to eq(1)

        # Only Book Two should remain
        expect(results.first['title']).to eq('Book Two')
      end

      it 'filters regardless of ToC status' do
        # Create ToCs with different statuses
        Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL1M',
          title: 'Book One',
          status: :empty
        )
        Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL2M',
          title: 'Book Two',
          status: :transcribed
        )

        get :search, params: { search: 'test' }

        results = assigns(:results)
        expect(results.length).to eq(1)
        expect(results.first['title']).to eq('Book Three')
      end
    end

    context 'when combining with fulltext_only filter' do
      let(:mixed_results) do
        {
          'numFound' => 4,
          'docs' => [
            {
              'title' => 'Fulltext Book',
              'has_fulltext' => true,
              'ebook_access' => 'public',
              'editions' => { 'docs' => [{ 'key' => '/books/OL1M' }] }
            },
            {
              'title' => 'Metadata Only Book',
              'has_fulltext' => false,
              'editions' => { 'docs' => [{ 'key' => '/books/OL2M' }] }
            }
          ]
        }
      end

      before do
        allow(mock_client).to receive(:search).and_return(mixed_results)
      end

      it 'applies both fulltext_only and existing ToC filters' do
        # Create a ToC for the fulltext book
        Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL1M',
          title: 'Fulltext Book',
          status: :empty
        )

        get :search, params: { search: 'test', fulltext_only: '1' }

        results = assigns(:results)
        # Should be empty because the only fulltext book already has a ToC
        expect(results.length).to eq(0)
      end
    end

    context 'pagination' do
      let(:large_search_results) do
        {
          'numFound' => 50,
          'docs' => (1..20).map do |i|
            {
              'title' => "Book #{i}",
              'author_name' => ["Author #{i}"],
              'has_fulltext' => true,
              'ebook_access' => 'public',
              'editions' => {
                'docs' => [
                  { 'key' => "/books/OL#{i}M" }
                ]
              }
            }
          end
        }
      end

      before do
        allow(mock_client).to receive(:search).and_return(large_search_results)
      end

      it 'defaults to page 1 when no page parameter provided' do
        get :search, params: { search: 'test' }

        expect(assigns(:current_page)).to eq(1)
      end

      it 'uses the page parameter when provided' do
        get :search, params: { search: 'test', page: 3 }

        expect(assigns(:current_page)).to eq(3)
      end

      it 'defaults to 20 results per page' do
        get :search, params: { search: 'test' }

        expect(assigns(:per_page)).to eq(20)
      end

      it 'uses the per_page parameter when provided' do
        get :search, params: { search: 'test', per_page: 50 }

        expect(assigns(:per_page)).to eq(50)
      end

      it 'calculates total pages correctly' do
        get :search, params: { search: 'test' }

        # 50 results / 20 per page = 3 pages
        expect(assigns(:total_pages)).to eq(3)
      end

      it 'passes pagination parameters to OpenLibrary client' do
        expect(mock_client).to receive(:search).with(hash_including(
          page: 2,
          per_page: 20
        )).and_return(large_search_results)

        get :search, params: { search: 'test', page: 2 }
      end

      it 'handles fractional page counts by ceiling' do
        # 45 results / 20 per page = 2.25 pages -> 3 pages
        results_45 = large_search_results.merge('numFound' => 45)
        allow(mock_client).to receive(:search).and_return(results_45)

        get :search, params: { search: 'test' }

        expect(assigns(:total_pages)).to eq(3)
      end
    end
  end
end

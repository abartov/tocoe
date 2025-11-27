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
  end
end

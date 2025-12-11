require 'rails_helper'

RSpec.describe Gutendex::Client do
  let(:client) { described_class.new }
  let(:api_url) { 'https://gutendex.toolforge.org' }

  before do
    allow(Rails.configuration.constants).to receive(:[]).with('gutendex_api_url').and_return(api_url)
  end

  describe '#book' do
    it 'fetches a specific book by ID' do
      book_data = {
        'id' => 1342,
        'title' => 'Pride and Prejudice',
        'authors' => [
          { 'name' => 'Austen, Jane', 'birth_year' => 1775, 'death_year' => 1817 }
        ],
        'formats' => {
          'text/html' => 'https://www.gutenberg.org/files/1342/1342-h/1342-h.htm',
          'text/plain' => 'https://www.gutenberg.org/files/1342/1342-0.txt'
        }
      }

      stub_request(:get, "#{api_url}/books/1342")
        .to_return(status: 200, body: book_data.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.book(1342)

      expect(result['id']).to eq(1342)
      expect(result['title']).to eq('Pride and Prejudice')
      expect(result['authors'].first['name']).to eq('Austen, Jane')
    end

    it 'raises an error when the API request fails' do
      stub_request(:get, "#{api_url}/books/9999")
        .to_return(status: 404, body: '{"detail": "Not found"}', headers: { 'Content-Type' => 'application/json' })

      expect { client.book(9999) }.to raise_error(RuntimeError, /FAILED/)
    end
  end

  describe '#search' do
    it 'searches for books by query' do
      search_response = {
        'count' => 100,
        'next' => nil,
        'previous' => nil,
        'results' => [
          {
            'id' => 1342,
            'title' => 'Pride and Prejudice',
            'authors' => [
              { 'name' => 'Austen, Jane', 'birth_year' => 1775, 'death_year' => 1817 }
            ]
          }
        ]
      }

      stub_request(:get, "#{api_url}/books?search=pride")
        .to_return(status: 200, body: search_response.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.search(query: 'pride')

      expect(result['count']).to eq(100)
      expect(result['numFound']).to eq(100)
      expect(result['results'].first['title']).to eq('Pride and Prejudice')
    end

    it 'supports pagination' do
      search_response = {
        'count' => 100,
        'next' => "#{api_url}/books?page=2",
        'previous' => nil,
        'results' => []
      }

      stub_request(:get, "#{api_url}/books?search=austen&page=2")
        .to_return(status: 200, body: search_response.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.search(query: 'austen', page: 2)

      expect(result['next']).to include('page=2')
    end

    it 'filters by language' do
      search_response = {
        'count' => 50,
        'next' => nil,
        'previous' => nil,
        'results' => []
      }

      stub_request(:get, "#{api_url}/books?languages=fr")
        .to_return(status: 200, body: search_response.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.search(languages: 'fr')

      expect(result['count']).to eq(50)
    end
  end

  describe '#fulltext_urls' do
    it 'returns format URLs for a book' do
      book_data = {
        'id' => 1342,
        'title' => 'Pride and Prejudice',
        'formats' => {
          'text/html' => 'https://www.gutenberg.org/files/1342/1342-h/1342-h.htm',
          'text/plain' => 'https://www.gutenberg.org/files/1342/1342-0.txt'
        }
      }

      stub_request(:get, "#{api_url}/books/1342")
        .to_return(status: 200, body: book_data.to_json, headers: { 'Content-Type' => 'application/json' })

      formats = client.fulltext_urls(1342)

      expect(formats['text/html']).to eq('https://www.gutenberg.org/files/1342/1342-h/1342-h.htm')
      expect(formats['text/plain']).to eq('https://www.gutenberg.org/files/1342/1342-0.txt')
    end

    it 'returns empty hash when API request fails' do
      stub_request(:get, "#{api_url}/books/9999")
        .to_return(status: 404, body: '{"detail": "Not found"}', headers: { 'Content-Type' => 'application/json' })

      formats = client.fulltext_urls(9999)

      expect(formats).to eq({})
    end
  end

  describe '#preferred_fulltext_url' do
    it 'prefers HTML format' do
      book_data = {
        'id' => 1342,
        'formats' => {
          'text/html' => 'https://www.gutenberg.org/files/1342/1342-h/1342-h.htm',
          'text/plain' => 'https://www.gutenberg.org/files/1342/1342-0.txt'
        }
      }

      stub_request(:get, "#{api_url}/books/1342")
        .to_return(status: 200, body: book_data.to_json, headers: { 'Content-Type' => 'application/json' })

      url = client.preferred_fulltext_url(1342)

      expect(url).to eq('https://www.gutenberg.org/files/1342/1342-h/1342-h.htm')
    end

    it 'falls back to plain text when HTML is not available' do
      book_data = {
        'id' => 1342,
        'formats' => {
          'text/plain; charset=utf-8' => 'https://www.gutenberg.org/files/1342/1342-0.txt'
        }
      }

      stub_request(:get, "#{api_url}/books/1342")
        .to_return(status: 200, body: book_data.to_json, headers: { 'Content-Type' => 'application/json' })

      url = client.preferred_fulltext_url(1342)

      expect(url).to eq('https://www.gutenberg.org/files/1342/1342-0.txt')
    end

    it 'returns nil when no fulltext is available' do
      book_data = {
        'id' => 1342,
        'formats' => {
          'application/epub+zip' => 'https://www.gutenberg.org/files/1342/1342.epub'
        }
      }

      stub_request(:get, "#{api_url}/books/1342")
        .to_return(status: 200, body: book_data.to_json, headers: { 'Content-Type' => 'application/json' })

      url = client.preferred_fulltext_url(1342)

      expect(url).to be_nil
    end
  end
end

require 'rails_helper'

RSpec.describe Gutendex::Client do
  let(:client) { described_class.new }

  describe '#book' do
    it 'fetches a specific book by ID' do
      # Use a real Project Gutenberg book ID (1342 = Pride and Prejudice)
      result = client.book(1342)

      expect(result['id']).to eq(1342)
      expect(result['title']).to include('Pride')
      expect(result['authors']).to be_an(Array)
      expect(result['authors'].first['name']).to include('Austen')
      expect(result['formats']).to be_a(Hash)
    end

    it 'raises an error when the book is not found' do
      # Use an ID that's unlikely to exist (very high number)
      expect { client.book(999999999) }.to raise_error(RuntimeError, /FAILED/)
    end
  end

  describe '#search' do
    it 'searches for books by query' do
      # Search for a well-known book
      result = client.search(query: 'pride prejudice')

      expect(result['count']).to be > 0
      expect(result['numFound']).to eq(result['count'])
      expect(result['results']).to be_an(Array)
      expect(result['results'].first).to have_key('title')
      expect(result['results'].first).to have_key('authors')
    end

    it 'supports pagination' do
      # Search for a common term to ensure multiple pages
      result = client.search(query: 'shakespeare', page: 2)

      # The response should have pagination metadata
      expect(result).to have_key('count')
      expect(result).to have_key('results')
      # Note: 'next' and 'previous' may be nil if there aren't enough results
    end

    it 'filters by language' do
      # Search for books in French
      result = client.search(languages: 'fr')

      expect(result['count']).to be > 0
      expect(result['results']).to be_an(Array)
    end
  end

  describe '#fulltext_urls' do
    it 'returns format URLs for a book' do
      # Use Pride and Prejudice (ID 1342)
      formats = client.fulltext_urls(1342)

      expect(formats).to be_a(Hash)
      expect(formats).not_to be_empty
      # Should have at least HTML or text format
      expect(formats.keys.any? { |k| k.include?('html') || k.include?('text') }).to be true
      # URLs should point to gutenberg.org
      expect(formats.values.first).to include('gutenberg.org')
    end

    it 'returns empty hash when API request fails' do
      # Use a non-existent book ID
      formats = client.fulltext_urls(999999999)

      expect(formats).to eq({})
    end
  end

  describe '#preferred_fulltext_url' do
    it 'returns an HTML or text URL for a book' do
      # Use Pride and Prejudice (ID 1342)
      url = client.preferred_fulltext_url(1342)

      expect(url).to be_a(String)
      expect(url).to include('gutenberg.org')
      # Should be HTML or text format
      expect(url).to match(/html|txt/)
    end

    it 'returns nil when API request fails' do
      # Use a non-existent book ID
      url = client.preferred_fulltext_url(999999999)

      expect(url).to be_nil
    end
  end
end

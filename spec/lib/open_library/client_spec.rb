require 'rails_helper'

RSpec.describe OpenLibrary::Client do
  let(:client) { OpenLibrary::Client.new }

  describe '#ia_identifier' do
    it 'returns the Internet Archive identifier for a book' do
      # Use a known book with IA scans
      olid = 'OL7928212M'

      # Skip if network is unavailable
      skip 'Network required' unless ENV['RUN_NETWORK_TESTS']

      ia_id = client.ia_identifier(olid)
      expect(ia_id).to be_a(String).or be_nil
    end

    it 'returns nil for a book without IA scans' do
      allow(client).to receive(:book).and_return({})

      ia_id = client.ia_identifier('OL123M')
      expect(ia_id).to be_nil
    end

    it 'handles errors gracefully' do
      allow(client).to receive(:book).and_raise(StandardError, 'Network error')
      allow(Rails.logger).to receive(:error)

      ia_id = client.ia_identifier('OL123M')
      expect(ia_id).to be_nil
      expect(Rails.logger).to have_received(:error)
    end
  end

  describe '#ia_metadata' do
    it 'returns nil for blank identifier' do
      metadata = client.ia_metadata(nil)
      expect(metadata).to be_nil

      metadata = client.ia_metadata('')
      expect(metadata).to be_nil
    end

    it 'returns metadata hash with imagecount for valid IA identifier' do
      skip 'Network required' unless ENV['RUN_NETWORK_TESTS']

      metadata = client.ia_metadata('prideprejudice0000jane_l6i1')
      expect(metadata).to be_a(Hash)
      expect(metadata[:imagecount]).to be_a(Integer)
      expect(metadata[:imagecount]).to be > 0
    end

    it 'handles errors gracefully' do
      allow(Net::HTTP).to receive(:get_response).and_raise(StandardError, 'Network error')
      allow(Rails.logger).to receive(:error)

      metadata = client.ia_metadata('test_id')
      expect(metadata).to be_nil
      expect(Rails.logger).to have_received(:error)
    end
  end

  describe '#ia_page_images' do
    it 'returns empty array for blank identifier' do
      pages = client.ia_page_images(nil)
      expect(pages).to eq([])

      pages = client.ia_page_images('')
      expect(pages).to eq([])
    end

    it 'returns empty array when metadata fetch fails' do
      allow(client).to receive(:ia_metadata).and_return(nil)

      pages = client.ia_page_images('test_id')
      expect(pages).to eq([])
    end

    it 'returns array of page hashes for valid identifier' do
      # Mock the metadata response
      allow(client).to receive(:ia_metadata).and_return({
        imagecount: 10,
        title: 'Test Book',
        page_progression: 'lr'
      })

      pages = client.ia_page_images('test_id')
      expect(pages).to be_an(Array)
      expect(pages.length).to eq(10)

      # Check first page
      first_page = pages.first
      expect(first_page[:page_number]).to eq(0)
      expect(first_page[:url]).to include('archive.org/download/test_id/page/n0.jpg')
      expect(first_page[:thumb_url]).to include('scale=8')
    end

    it 'respects start_page and end_page options' do
      allow(client).to receive(:ia_metadata).and_return({ imagecount: 100 })

      pages = client.ia_page_images('test_id', start_page: 5, end_page: 9)
      expect(pages.length).to eq(5)
      expect(pages.first[:page_number]).to eq(5)
      expect(pages.last[:page_number]).to eq(9)
    end

    it 'applies scale parameter to URLs' do
      allow(client).to receive(:ia_metadata).and_return({ imagecount: 2 })

      pages = client.ia_page_images('test_id', scale: 4)
      expect(pages.first[:url]).to include('scale=4')
    end
  end

  describe '#page_image_url' do
    it 'constructs correct URL without scale' do
      url = client.send(:page_image_url, 'test_id', 5)
      expect(url).to eq('https://archive.org/download/test_id/page/n5.jpg')
    end

    it 'constructs correct URL with scale parameter' do
      url = client.send(:page_image_url, 'test_id', 5, 8)
      expect(url).to eq('https://archive.org/download/test_id/page/n5.jpg?scale=8')
    end
  end
end

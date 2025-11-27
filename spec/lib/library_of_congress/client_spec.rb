require 'rails_helper'
require 'library_of_congress/client'

RSpec.describe LibraryOfCongress::Client do
  let(:client) { described_class.new }

  describe '#search_subjects' do
    it 'normalizes queries by replacing space-dash-dash-space with double dash' do
      # Mock the HTTP response
      mock_response = double('response', success?: true, body: '[]')
      allow(described_class).to receive(:get).and_return(mock_response)

      client.search_subjects('Fiction -- Adventure')

      # Verify that the query was normalized and includes the collection scope
      expect(described_class).to have_received(:get).with(
        '/search/',
        query: hash_including(q: 'Fiction--Adventure cs:http://id.loc.gov/authorities/subjects')
      )
    end

    it 'returns empty array on error' do
      allow(described_class).to receive(:get).and_raise(StandardError.new('API error'))

      result = client.search_subjects('Fiction')

      expect(result).to eq([])
    end

    it 'returns empty array when API request fails' do
      mock_response = double('response', success?: false)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_subjects('Fiction')

      expect(result).to eq([])
    end

    it 'parses search results correctly' do
      mock_data = [
        { 'uri' => 'http://id.loc.gov/authorities/subjects/sh85048050', 'label' => 'Fiction', 'score' => 100 },
        { 'uri' => 'http://id.loc.gov/authorities/subjects/sh85048051', 'aLabel' => 'Fiction--Adventure', 'score' => 95 }
      ]
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_subjects('Fiction')

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first[:uri]).to eq('http://id.loc.gov/authorities/subjects/sh85048050')
      expect(result.first[:label]).to eq('Fiction')
      expect(result.last[:label]).to eq('Fiction--Adventure')
    end
  end

  describe '#find_exact_match' do
    it 'returns exact match when label matches normalized query' do
      mock_data = [
        { 'uri' => 'http://id.loc.gov/authorities/subjects/sh85048050', 'label' => 'Fiction', 'score' => 100 },
        { 'uri' => 'http://id.loc.gov/authorities/subjects/sh85048051', 'label' => 'Historical fiction', 'score' => 95 }
      ]
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.find_exact_match('Fiction')

      expect(result).not_to be_nil
      expect(result[:uri]).to eq('http://id.loc.gov/authorities/subjects/sh85048050')
      expect(result[:label]).to eq('Fiction')
    end

    it 'returns nil when no exact match found' do
      mock_data = [
        { 'uri' => 'http://id.loc.gov/authorities/subjects/sh85048051', 'label' => 'Historical fiction', 'score' => 95 }
      ]
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.find_exact_match('Fiction')

      expect(result).to be_nil
    end

    it 'normalizes both query and result labels for comparison' do
      mock_data = [
        { 'uri' => 'http://id.loc.gov/authorities/subjects/sh85048050', 'label' => 'Fiction--Adventure', 'score' => 100 }
      ]
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.find_exact_match('Fiction -- Adventure')

      expect(result).not_to be_nil
      expect(result[:uri]).to eq('http://id.loc.gov/authorities/subjects/sh85048050')
    end

    it 'is case-insensitive' do
      mock_data = [
        { 'uri' => 'http://id.loc.gov/authorities/subjects/sh85048050', 'label' => 'Fiction', 'score' => 100 }
      ]
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.find_exact_match('FICTION')

      expect(result).not_to be_nil
      expect(result[:label]).to eq('Fiction')
    end
  end
end

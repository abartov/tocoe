require 'rails_helper'
require 'library_of_congress/client'

RSpec.describe LibraryOfCongress::Client do
  let(:client) { described_class.new }

  # Helper method to create Atom feed entry
  def create_atom_entry(uri, label)
    entry = ["atom:entry", {"xmlns:atom" => "http://www.w3.org/2005/Atom"}]

    # Add title if label is not nil
    if label
      entry << ["atom:title", {"xmlns:atom" => "http://www.w3.org/2005/Atom"}, label]
    end

    # Add link if uri is not nil
    if uri
      entry << ["atom:link", {"xmlns:atom" => "http://www.w3.org/2005/Atom", "rel" => "alternate", "href" => uri}]
    end

    entry
  end

  # Helper method to create Atom feed with entries
  def create_atom_feed(entries)
    ["atom:feed",
     {"xmlns:atom" => "http://www.w3.org/2005/Atom"},
     ["atom:title", {"xmlns:atom" => "http://www.w3.org/2005/Atom"}, "Library of Congress Authorities and Vocabulary Service: Search Results"],
     *entries]
  end

  describe '#search_subjects' do
    it 'normalizes queries by replacing space-dash-dash-space with double dash' do
      # Mock the HTTP response
      empty_feed = create_atom_feed([])
      mock_response = double('response', success?: true, body: empty_feed.to_json)
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
      mock_data = create_atom_feed([
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', 'Fiction'),
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048051', 'Fiction--Adventure')
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_subjects('Fiction')

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first[:uri]).to eq('http://id.loc.gov/authorities/subjects/sh85048050')
      expect(result.first[:label]).to eq('Fiction')
      expect(result.last[:label]).to eq('Fiction--Adventure')
    end

    it 'filters out results with nil uri' do
      mock_data = create_atom_feed([
        create_atom_entry(nil, 'Fiction'),
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048051', 'Valid Result')
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_subjects('Fiction')

      expect(result.length).to eq(1)
      expect(result.first[:label]).to eq('Valid Result')
    end

    it 'filters out results with empty uri' do
      mock_data = create_atom_feed([
        create_atom_entry('', 'Fiction'),
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048051', 'Valid Result')
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_subjects('Fiction')

      expect(result.length).to eq(1)
      expect(result.first[:label]).to eq('Valid Result')
    end

    it 'filters out results with nil label' do
      mock_data = create_atom_feed([
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', nil),
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048051', 'Valid Result')
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_subjects('Fiction')

      expect(result.length).to eq(1)
      expect(result.first[:label]).to eq('Valid Result')
    end

    it 'filters out results with empty label' do
      mock_data = create_atom_feed([
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', ''),
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048051', 'Valid Result')
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_subjects('Fiction')

      expect(result.length).to eq(1)
      expect(result.first[:label]).to eq('Valid Result')
    end

    it 'returns empty array when all results have nil or empty uri/label' do
      mock_data = create_atom_feed([
        create_atom_entry(nil, 'Fiction'),
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', ''),
        create_atom_entry('', 'Test')
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_subjects('Fiction')

      expect(result).to eq([])
    end
  end

  describe '#find_exact_match' do
    it 'returns exact match when label matches normalized query' do
      mock_data = create_atom_feed([
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', 'Fiction'),
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048051', 'Historical fiction')
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.find_exact_match('Fiction')

      expect(result).not_to be_nil
      expect(result[:uri]).to eq('http://id.loc.gov/authorities/subjects/sh85048050')
      expect(result[:label]).to eq('Fiction')
    end

    it 'returns nil when no exact match found' do
      mock_data = create_atom_feed([
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048051', 'Historical fiction')
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.find_exact_match('Fiction')

      expect(result).to be_nil
    end

    it 'normalizes both query and result labels for comparison' do
      mock_data = create_atom_feed([
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', 'Fiction--Adventure')
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.find_exact_match('Fiction -- Adventure')

      expect(result).not_to be_nil
      expect(result[:uri]).to eq('http://id.loc.gov/authorities/subjects/sh85048050')
    end

    it 'is case-insensitive' do
      mock_data = create_atom_feed([
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', 'Fiction')
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.find_exact_match('FICTION')

      expect(result).not_to be_nil
      expect(result[:label]).to eq('Fiction')
    end

    it 'handles search results with nil labels without crashing' do
      mock_data = create_atom_feed([
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', nil),
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048051', 'Fiction')
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.find_exact_match('Fiction')

      expect(result).not_to be_nil
      expect(result[:label]).to eq('Fiction')
    end

    it 'returns nil when all results have nil labels' do
      mock_data = create_atom_feed([
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', nil),
        create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048051', nil)
      ])
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.find_exact_match('Fiction')

      expect(result).to be_nil
    end
  end
end

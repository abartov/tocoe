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
  def create_atom_feed(entries, next_link: nil)
    feed = ["atom:feed",
            {"xmlns:atom" => "http://www.w3.org/2005/Atom"},
            ["atom:title", {"xmlns:atom" => "http://www.w3.org/2005/Atom"}, "Library of Congress Authorities and Vocabulary Service: Search Results"]]

    # Add next link if provided
    if next_link
      feed << ["atom:link", {"xmlns:atom" => "http://www.w3.org/2005/Atom", "rel" => "next", "href" => next_link}]
    end

    # Add entries
    feed.concat(entries)
    feed
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
        a_string_matching(/Fiction--Adventure/)
      ).at_least(:once)
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

    context 'pagination' do
      it 'retrieves results from multiple pages when next link is present' do
        # First page with 2 results and next link
        page1_data = create_atom_feed([
          create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', 'Fiction'),
          create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048051', 'Science Fiction')
        ], next_link: 'http://id.loc.gov/search/?q=Fiction&start=3&format=json')

        # Second page with 2 results and no next link
        page2_data = create_atom_feed([
          create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048052', 'Historical Fiction'),
          create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048053', 'Fantasy Fiction')
        ])

        page1_response = double('response', success?: true, body: page1_data.to_json)
        page2_response = double('response', success?: true, body: page2_data.to_json)

        # Mock the get method to return different responses based on the URL
        allow(described_class).to receive(:get).and_return(page1_response, page2_response)

        result = client.search_subjects('Fiction')

        expect(result.length).to eq(4)
        expect(result[0][:label]).to eq('Fiction')
        expect(result[1][:label]).to eq('Science Fiction')
        expect(result[2][:label]).to eq('Historical Fiction')
        expect(result[3][:label]).to eq('Fantasy Fiction')

        # Verify that two requests were made
        expect(described_class).to have_received(:get).twice
      end

      it 'returns single page results when no next link is present' do
        mock_data = create_atom_feed([
          create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', 'Fiction')
        ])
        mock_response = double('response', success?: true, body: mock_data.to_json)
        allow(described_class).to receive(:get).and_return(mock_response)

        result = client.search_subjects('Fiction')

        expect(result.length).to eq(1)
        expect(result.first[:label]).to eq('Fiction')

        # Verify that only one request was made
        expect(described_class).to have_received(:get).once
      end

      it 'stops pagination after max_pages limit' do
        # Create mock data with next link that would continue indefinitely
        mock_data = create_atom_feed([
          create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', 'Fiction')
        ], next_link: 'http://id.loc.gov/search/?q=Fiction&start=2&format=json')

        mock_response = double('response', success?: true, body: mock_data.to_json)
        allow(described_class).to receive(:get).and_return(mock_response)

        result = client.search_subjects('Fiction')

        # Should stop at max_pages (100) to prevent infinite loop
        # Each page has 1 result, so 100 pages = 100 results
        expect(result.length).to eq(100)
        expect(described_class).to have_received(:get).exactly(100).times
      end

      it 'returns partial results when error occurs on subsequent page' do
        # First page with results and next link
        page1_data = create_atom_feed([
          create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', 'Fiction')
        ], next_link: 'http://id.loc.gov/search/?q=Fiction&start=2&format=json')

        page1_response = double('response', success?: true, body: page1_data.to_json)
        page2_response = double('response', success?: false)

        allow(described_class).to receive(:get).and_return(page1_response, page2_response)

        result = client.search_subjects('Fiction')

        # Should return results from first page even though second page failed
        expect(result.length).to eq(1)
        expect(result.first[:label]).to eq('Fiction')
      end

      it 'handles empty pages in pagination' do
        # First page with results and next link
        page1_data = create_atom_feed([
          create_atom_entry('http://id.loc.gov/authorities/subjects/sh85048050', 'Fiction')
        ], next_link: 'http://id.loc.gov/search/?q=Fiction&start=2&format=json')

        # Second page with no results and no next link
        page2_data = create_atom_feed([])

        page1_response = double('response', success?: true, body: page1_data.to_json)
        page2_response = double('response', success?: true, body: page2_data.to_json)

        allow(described_class).to receive(:get).and_return(page1_response, page2_response)

        result = client.search_subjects('Fiction')

        expect(result.length).to eq(1)
        expect(result.first[:label]).to eq('Fiction')
      end
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

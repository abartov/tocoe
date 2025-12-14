require 'rails_helper'
require 'subject_headings/wikidata_client'

RSpec.describe SubjectHeadings::WikidataClient do
  let(:client) { SubjectHeadings::WikidataClient.new }

  describe '#search' do
    context 'with a valid query' do
      it 'returns Wikidata entity results from the API' do
        response = client.search('Douglas Adams')

        expect(response).to be_a(Hash)
        expect(response).to have_key(:results)
        expect(response).to have_key(:has_more)
        expect(response[:results]).to be_an(Array)
        expect(response[:results]).not_to be_empty

        first_result = response[:results].first
        expect(first_result).to have_key(:uri)
        expect(first_result).to have_key(:label)
        expect(first_result).to have_key(:instance_of)
        expect(first_result[:uri]).to match(/^https?:\/\/www\.wikidata\.org\/entity\/Q\d+/)
        expect(first_result[:label]).to be_a(String)
        expect(first_result[:instance_of]).to be_an(Array)
      end

      it 'limits results based on count parameter' do
        response = client.search('science', count: 5)

        expect(response[:results].length).to be <= 5
      end

      it 'parses the API response with instance_of types' do
        response = client.search('mathematics')

        expect(response[:results]).to be_an(Array)
        expect(response[:results]).not_to be_empty

        # Verify that results have proper structure
        first_result = response[:results].first
        expect(first_result).to have_key(:uri)
        expect(first_result).to have_key(:label)
        expect(first_result).to have_key(:instance_of)
        expect(first_result[:instance_of]).to be_an(Array)
      end

      it 'supports pagination with offset parameter' do
        response_page1 = client.search('science', count: 5, offset: 0)
        response_page2 = client.search('science', count: 5, offset: 5)

        expect(response_page1[:results]).to be_an(Array)
        expect(response_page2[:results]).to be_an(Array)

        # Results should be different for different pages
        if response_page1[:results].any? && response_page2[:results].any?
          expect(response_page1[:results].first[:uri]).not_to eq(response_page2[:results].first[:uri])
        end
      end
    end

    context 'with an empty query' do
      it 'returns empty results' do
        response = client.search('')
        expect(response).to eq({ results: [], has_more: false })
      end

      it 'returns empty results for nil query' do
        response = client.search(nil)
        expect(response).to eq({ results: [], has_more: false })
      end
    end

    context 'error handling' do
      it 'handles network errors gracefully' do
        # Test with an intentionally malformed client that will fail
        allow(Net::HTTP).to receive(:get_response).and_raise(StandardError.new('Network error'))

        expect(Rails.logger).to receive(:error).with(/Wikidata API error/)
        response = client.search('test')
        expect(response).to eq({ results: [], has_more: false })
      end
    end
  end

  describe '#get_library_of_congress_id' do
    context 'with a valid entity that has P244' do
      it 'returns the Library of Congress Authority ID' do
        # Q395 (mathematics) has P244: sh85082139
        lc_id = client.get_library_of_congress_id('Q395')
        expect(lc_id).to eq('sh85082139')
      end
    end

    context 'with an entity that does not have P244' do
      it 'returns nil' do
        # Q9484 does not have P244 (LC authority ID)
        lc_id = client.get_library_of_congress_id('Q9484')
        expect(lc_id).to be_nil
      end
    end

    context 'with an empty entity_id' do
      it 'returns nil for blank string' do
        lc_id = client.get_library_of_congress_id('')
        expect(lc_id).to be_nil
      end

      it 'returns nil for nil' do
        lc_id = client.get_library_of_congress_id(nil)
        expect(lc_id).to be_nil
      end
    end

    context 'error handling' do
      it 'handles network errors gracefully' do
        allow(Net::HTTP).to receive(:get_response).and_raise(StandardError.new('Network error'))

        expect(Rails.logger).to receive(:error).with(/Wikidata API error fetching P244/)
        lc_id = client.get_library_of_congress_id('Q395')
        expect(lc_id).to be_nil
      end
    end
  end

  describe '#find_entity_by_library_of_congress_id' do
    context 'with a valid LC authority ID that exists in Wikidata' do
      it 'returns the Wikidata entity ID and label' do
        # sh85082139 (mathematics) should map to Q395
        result = client.find_entity_by_library_of_congress_id('sh85082139')

        expect(result).to be_a(Hash)
        expect(result[:entity_id]).to eq('Q395')
        expect(result[:label]).to be_present
        expect(result[:label]).to be_a(String)
      end

      it 'parses the SPARQL response correctly for another entity' do
        # sh85118553 (science) should map to Q336
        result = client.find_entity_by_library_of_congress_id('sh85118553')

        expect(result).to be_a(Hash)
        expect(result[:entity_id]).to eq('Q336')
        expect(result[:label]).to be_present
      end
    end

    context 'when no entity is found with the LC ID' do
      it 'returns nil for non-existent LC ID' do
        result = client.find_entity_by_library_of_congress_id('sh99999999')
        expect(result).to be_nil
      end
    end

    context 'with an empty LC ID' do
      it 'returns nil for blank string' do
        result = client.find_entity_by_library_of_congress_id('')
        expect(result).to be_nil
      end

      it 'returns nil for nil' do
        result = client.find_entity_by_library_of_congress_id(nil)
        expect(result).to be_nil
      end
    end

    context 'error handling' do
      it 'handles network errors gracefully' do
        # Mock the HTTP instance to raise an error
        http_instance = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_instance)
        allow(http_instance).to receive(:use_ssl=)
        allow(http_instance).to receive(:request).and_raise(StandardError.new('Network error'))

        expect(Rails.logger).to receive(:error).with(/Wikidata SPARQL error/)
        result = client.find_entity_by_library_of_congress_id('sh85082139')
        expect(result).to be_nil
      end
    end
  end
end

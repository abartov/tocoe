require 'rails_helper'
require 'subject_headings/wikidata_client'

RSpec.describe SubjectHeadings::WikidataClient do
  let(:client) { SubjectHeadings::WikidataClient.new }

  describe '#search' do
    context 'with a valid query' do
      it 'returns Wikidata entity results from the API', :skip_in_ci do
        # This is a live API test - skip if needed in CI
        results = client.search('Douglas Adams')

        expect(results).to be_an(Array)
        expect(results).not_to be_empty

        first_result = results.first
        expect(first_result).to have_key(:uri)
        expect(first_result).to have_key(:label)
        expect(first_result[:uri]).to match(/^https?:\/\/www\.wikidata\.org\/entity\/Q\d+/)
        expect(first_result[:label]).to be_a(String)
      end

      it 'limits results based on count parameter', :skip_in_ci do
        results = client.search('science', count: 5)

        expect(results.length).to be <= 5
      end
    end

    context 'with an empty query' do
      it 'returns an empty array' do
        results = client.search('')
        expect(results).to eq([])
      end

      it 'returns an empty array for nil query' do
        results = client.search(nil)
        expect(results).to eq([])
      end
    end

    context 'when API returns an error' do
      before do
        allow(Net::HTTP).to receive(:get_response).and_raise(StandardError.new('Network error'))
      end

      it 'logs the error and returns an empty array' do
        expect(Rails.logger).to receive(:error).with(/Wikidata API error/)
        results = client.search('test')
        expect(results).to eq([])
      end
    end

    context 'when API returns non-200 status' do
      before do
        response = instance_double(Net::HTTPResponse, code: '500', body: '')
        allow(Net::HTTP).to receive(:get_response).and_return(response)
      end

      it 'logs the error and returns an empty array' do
        expect(Rails.logger).to receive(:error).with(/Wikidata API error/)
        results = client.search('test')
        expect(results).to eq([])
      end
    end

    context 'with stubbed API response' do
      let(:mock_search_response) do
        {
          searchinfo: { search: 'douglas adams' },
          search: [
            {
              id: 'Q42',
              label: 'Douglas Adams',
              description: 'English writer and humorist'
            },
            {
              id: 'Q5685',
              label: 'The Hitchhiker\'s Guide to the Galaxy',
              description: 'science fiction series by Douglas Adams'
            }
          ]
        }.to_json
      end

      let(:mock_entities_response) do
        {
          entities: {
            'Q42' => {
              claims: {
                'P31' => [
                  {
                    mainsnak: {
                      datavalue: {
                        value: { id: 'Q5' }
                      }
                    }
                  }
                ]
              }
            },
            'Q5685' => {
              claims: {
                'P31' => [
                  {
                    mainsnak: {
                      datavalue: {
                        value: { id: 'Q8261' }
                      }
                    }
                  }
                ]
              }
            }
          }
        }.to_json
      end

      let(:mock_labels_response) do
        {
          entities: {
            'Q5' => {
              labels: {
                'en' => { value: 'human' }
              }
            },
            'Q8261' => {
              labels: {
                'en' => { value: 'novel' }
              }
            }
          }
        }.to_json
      end

      before do
        # Stub the three different API calls based on URL parameters
        allow(Net::HTTP).to receive(:get_response) do |uri|
          url = uri.to_s
          response_body = if url.include?('wbsearchentities')
                            mock_search_response
                          elsif url.include?('wbgetentities') && url.include?('props=claims')
                            mock_entities_response
                          elsif url.include?('wbgetentities') && url.include?('props=labels')
                            mock_labels_response
                          else
                            '{}'
                          end
          instance_double(Net::HTTPResponse, code: '200', body: response_body, is_a?: true)
        end
      end

      it 'parses the API response correctly' do
        results = client.search('douglas adams')

        expect(results.length).to eq(2)
        expect(results[0]).to eq(
          uri: 'http://www.wikidata.org/entity/Q42',
          label: 'Douglas Adams',
          instance_of: ['human']
        )
        expect(results[1]).to eq(
          uri: 'http://www.wikidata.org/entity/Q5685',
          label: 'The Hitchhiker\'s Guide to the Galaxy',
          instance_of: ['novel']
        )
      end
    end
  end

  describe '#get_library_of_congress_id' do
    context 'with a valid entity that has P244' do
      it 'returns the Library of Congress Authority ID', :skip_in_ci do
        # Q395 (mathematics) has P244: sh85082139
        lc_id = client.get_library_of_congress_id('Q395')
        expect(lc_id).to eq('sh85082139')
      end
    end

    context 'with an entity that does not have P244' do
      let(:mock_entities_response_no_p244) do
        {
          entities: {
            'Q42' => {
              claims: {
                'P31' => [
                  {
                    mainsnak: {
                      datavalue: {
                        value: { id: 'Q5' }
                      }
                    }
                  }
                ]
              }
            }
          }
        }.to_json
      end

      before do
        allow(Net::HTTP).to receive(:get_response) do |uri|
          instance_double(Net::HTTPResponse, code: '200', body: mock_entities_response_no_p244, is_a?: true)
        end
      end

      it 'returns nil' do
        lc_id = client.get_library_of_congress_id('Q42')
        expect(lc_id).to be_nil
      end
    end

    context 'with stubbed API response containing P244' do
      let(:mock_entities_response_with_p244) do
        {
          entities: {
            'Q395' => {
              claims: {
                'P244' => [
                  {
                    mainsnak: {
                      datavalue: {
                        value: 'sh85082139'
                      }
                    }
                  }
                ],
                'P31' => [
                  {
                    mainsnak: {
                      datavalue: {
                        value: { id: 'Q11862829' }
                      }
                    }
                  }
                ]
              }
            }
          }
        }.to_json
      end

      before do
        allow(Net::HTTP).to receive(:get_response) do |uri|
          instance_double(Net::HTTPResponse, code: '200', body: mock_entities_response_with_p244, is_a?: true)
        end
      end

      it 'parses the P244 value correctly' do
        lc_id = client.get_library_of_congress_id('Q395')
        expect(lc_id).to eq('sh85082139')
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

    context 'when API returns an error' do
      before do
        allow(Net::HTTP).to receive(:get_response).and_raise(StandardError.new('Network error'))
      end

      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/Wikidata API error fetching P244/)
        lc_id = client.get_library_of_congress_id('Q395')
        expect(lc_id).to be_nil
      end
    end
  end

  describe '#find_entity_by_library_of_congress_id' do
    context 'with a valid LC authority ID that exists in Wikidata' do
      it 'returns the Wikidata entity ID and label', :skip_in_ci do
        # sh85082139 (mathematics) should map to Q395
        result = client.find_entity_by_library_of_congress_id('sh85082139')
        expect(result).to be_a(Hash)
        expect(result[:entity_id]).to eq('Q395')
        expect(result[:label]).to be_present
      end
    end

    context 'with stubbed SPARQL response' do
      let(:mock_sparql_response) do
        {
          head: { vars: ['item', 'itemLabel'] },
          results: {
            bindings: [
              {
                item: { type: 'uri', value: 'http://www.wikidata.org/entity/Q395' },
                itemLabel: { type: 'literal', value: 'mathematics' }
              }
            ]
          }
        }.to_json
      end

      before do
        allow(Net::HTTP).to receive(:get_response) do |uri|
          instance_double(Net::HTTPResponse, code: '200', body: mock_sparql_response, is_a?: true)
        end
      end

      it 'parses the SPARQL response correctly' do
        result = client.find_entity_by_library_of_congress_id('sh85082139')
        expect(result).to eq(
          entity_id: 'Q395',
          label: 'mathematics'
        )
      end
    end

    context 'when no entity is found with the LC ID' do
      let(:mock_empty_response) do
        {
          head: { vars: ['item', 'itemLabel'] },
          results: {
            bindings: []
          }
        }.to_json
      end

      before do
        allow(Net::HTTP).to receive(:get_response) do |uri|
          instance_double(Net::HTTPResponse, code: '200', body: mock_empty_response, is_a?: true)
        end
      end

      it 'returns nil' do
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

    context 'when SPARQL endpoint returns an error' do
      before do
        allow(Net::HTTP).to receive(:get_response).and_raise(StandardError.new('Network error'))
      end

      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/Wikidata SPARQL error/)
        result = client.find_entity_by_library_of_congress_id('sh85082139')
        expect(result).to be_nil
      end
    end

    context 'when SPARQL endpoint returns non-200 status' do
      before do
        response = instance_double(Net::HTTPResponse, code: '500', body: '', is_a?: false)
        allow(Net::HTTP).to receive(:get_response).and_return(response)
      end

      it 'returns nil' do
        result = client.find_entity_by_library_of_congress_id('sh85082139')
        expect(result).to be_nil
      end
    end
  end
end

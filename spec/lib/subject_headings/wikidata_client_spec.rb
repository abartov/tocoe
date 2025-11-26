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
      let(:mock_response) do
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

      before do
        response = instance_double(Net::HTTPResponse, code: '200', body: mock_response)
        allow(Net::HTTP).to receive(:get_response).and_return(response)
      end

      it 'parses the API response correctly' do
        results = client.search('douglas adams')

        expect(results.length).to eq(2)
        expect(results[0]).to eq(
          uri: 'http://www.wikidata.org/entity/Q42',
          label: 'Douglas Adams'
        )
        expect(results[1]).to eq(
          uri: 'http://www.wikidata.org/entity/Q5685',
          label: 'The Hitchhiker\'s Guide to the Galaxy'
        )
      end
    end
  end
end

require 'rails_helper'
require 'subject_headings/lcsh_client'

RSpec.describe SubjectHeadings::LcshClient do
  let(:client) { SubjectHeadings::LcshClient.new }

  describe '#search' do
    context 'with a valid query' do
      it 'returns subject heading results from the LCSH API', :skip_in_ci do
        # This is a live API test - skip if needed in CI
        response = client.search('whales')

        expect(response).to be_a(Hash)
        expect(response).to have_key(:results)
        expect(response).to have_key(:has_more)
        expect(response[:results]).to be_an(Array)
        expect(response[:results]).not_to be_empty

        first_result = response[:results].first
        expect(first_result).to have_key(:uri)
        expect(first_result).to have_key(:label)
        expect(first_result[:uri]).to match(/^https?:\/\/id\.loc\.gov\//)
        expect(first_result[:label]).to be_a(String)
      end

      it 'limits results based on count parameter', :skip_in_ci do
        response = client.search('science', count: 5)

        expect(response[:results].length).to be <= 5
      end

      it 'supports pagination with offset parameter', :skip_in_ci do
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

    context 'when API returns an error' do
      before do
        allow(Net::HTTP).to receive(:get_response).and_raise(StandardError.new('Network error'))
      end

      it 'logs the error and returns empty results' do
        expect(Rails.logger).to receive(:error).with(/LCSH API error/)
        response = client.search('test')
        expect(response).to eq({ results: [], has_more: false })
      end
    end

    context 'when API returns non-200 status' do
      before do
        response = instance_double(Net::HTTPResponse, code: '500', body: '')
        allow(Net::HTTP).to receive(:get_response).and_return(response)
      end

      it 'logs the error and returns empty results' do
        expect(Rails.logger).to receive(:error).with(/LCSH API error/)
        response = client.search('test')
        expect(response).to eq({ results: [], has_more: false })
      end
    end

    context 'with stubbed API response' do
      let(:mock_response) do
        {
          q: 'whales',
          hits: [
            {
              suggestLabel: 'Whales',
              uri: 'http://id.loc.gov/authorities/subjects/sh85146352',
              aLabel: 'Whales'
            },
            {
              suggestLabel: 'Whales--Anatomy',
              uri: 'http://id.loc.gov/authorities/subjects/sh85146353',
              aLabel: 'Whales--Anatomy'
            }
          ]
        }.to_json
      end

      before do
        response = instance_double(Net::HTTPResponse, code: '200', body: mock_response)
        allow(Net::HTTP).to receive(:get_response).and_return(response)
      end

      it 'parses the API response correctly' do
        response = client.search('whales')

        expect(response).to be_a(Hash)
        expect(response[:results].length).to eq(2)
        expect(response[:has_more]).to eq(false)
        expect(response[:results][0]).to eq(
          uri: 'http://id.loc.gov/authorities/subjects/sh85146352',
          label: 'Whales',
          alt_labels: [],
          broader: [],
          lc_id: 'sh85146352'
        )
        expect(response[:results][1]).to eq(
          uri: 'http://id.loc.gov/authorities/subjects/sh85146353',
          label: 'Whales--Anatomy',
          alt_labels: [],
          broader: [],
          lc_id: 'sh85146353'
        )
      end

      it 'handles pagination correctly' do
        # Get first result only
        response = client.search('whales', count: 1, offset: 0)
        expect(response[:results].length).to eq(1)
        expect(response[:results][0][:label]).to eq('Whales')
        expect(response[:has_more]).to eq(true) # More results available

        # Get second result only
        response = client.search('whales', count: 1, offset: 1)
        expect(response[:results].length).to eq(1)
        expect(response[:results][0][:label]).to eq('Whales--Anatomy')
        expect(response[:has_more]).to eq(false) # No more results
      end
    end
  end
end

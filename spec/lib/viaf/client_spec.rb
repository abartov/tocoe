require 'rails_helper'
require 'viaf/client'

RSpec.describe Viaf::Client do
  let(:client) { described_class.new }

  describe '#search_person' do
    it 'returns empty array for nil query' do
      result = client.search_person(nil)
      expect(result).to eq([])
    end

    it 'returns empty array for empty query' do
      result = client.search_person('')
      expect(result).to eq([])
    end

    it 'returns empty array for whitespace-only query' do
      result = client.search_person('   ')
      expect(result).to eq([])
    end

    it 'returns empty array on API error' do
      allow(described_class).to receive(:get).and_raise(StandardError.new('Network error'))
      allow(Rails.logger).to receive(:error)

      result = client.search_person('Shakespeare')

      expect(result).to eq([])
      expect(Rails.logger).to have_received(:error).with(/VIAF API error/)
    end

    it 'returns empty array when API request fails' do
      mock_response = double('response', success?: false)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_person('Shakespeare')

      expect(result).to eq([])
    end

    it 'parses VIAF results correctly' do
      mock_data = {
        'result' => [
          { 'viafid' => '96994048', 'term' => 'Shakespeare, William, 1564-1616' },
          { 'viafid' => '12345678', 'term' => 'Shakespeare, John' }
        ]
      }
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_person('Shakespeare')

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first[:viaf_id]).to eq(96994048)
      expect(result.first[:label]).to eq('Shakespeare, William, 1564-1616')
      expect(result.last[:viaf_id]).to eq(12345678)
      expect(result.last[:label]).to eq('Shakespeare, John')
    end

    it 'uses displayForm when term is not present' do
      mock_data = {
        'result' => [
          { 'viafid' => '96994048', 'displayForm' => 'Shakespeare, William, 1564-1616' }
        ]
      }
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_person('Shakespeare')

      expect(result.first[:label]).to eq('Shakespeare, William, 1564-1616')
    end

    it 'provides fallback label when neither term nor displayForm is present' do
      mock_data = {
        'result' => [
          { 'viafid' => '96994048' }
        ]
      }
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_person('Shakespeare')

      expect(result.first[:label]).to eq('VIAF ID: 96994048')
    end

    it 'filters out results without viafid' do
      mock_data = {
        'result' => [
          { 'term' => 'No VIAF ID here' },
          { 'viafid' => '96994048', 'term' => 'Shakespeare, William, 1564-1616' }
        ]
      }
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_person('Shakespeare')

      expect(result.length).to eq(1)
      expect(result.first[:label]).to eq('Shakespeare, William, 1564-1616')
    end

    it 'filters out results with empty viafid' do
      mock_data = {
        'result' => [
          { 'viafid' => '', 'term' => 'Empty VIAF ID' },
          { 'viafid' => '96994048', 'term' => 'Shakespeare, William, 1564-1616' }
        ]
      }
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_person('Shakespeare')

      expect(result.length).to eq(1)
      expect(result.first[:label]).to eq('Shakespeare, William, 1564-1616')
    end

    it 'returns empty array when result array is missing' do
      mock_data = {}
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_person('Shakespeare')

      expect(result).to eq([])
    end

    it 'returns empty array when result is not an array' do
      mock_data = { 'result' => 'not an array' }
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_person('Shakespeare')

      expect(result).to eq([])
    end

    it 'returns empty array when all results are filtered out' do
      mock_data = {
        'result' => [
          { 'term' => 'No VIAF ID 1' },
          { 'viafid' => '', 'term' => 'Empty VIAF ID' },
          { 'term' => 'No VIAF ID 2' }
        ]
      }
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_person('Shakespeare')

      expect(result).to eq([])
    end

    it 'limits results to 30 items' do
      # Create 50 mock results
      mock_results = (1..50).map do |i|
        { 'viafid' => i.to_s, 'term' => "Person #{i}" }
      end
      mock_data = { 'result' => mock_results }
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_person('Person')

      expect(result.length).to eq(30)
      expect(result.first[:label]).to eq('Person 1')
      expect(result.last[:label]).to eq('Person 30')
    end

    it 'converts viafid to integer' do
      mock_data = {
        'result' => [
          { 'viafid' => '96994048', 'term' => 'Shakespeare, William, 1564-1616' }
        ]
      }
      mock_response = double('response', success?: true, body: mock_data.to_json)
      allow(described_class).to receive(:get).and_return(mock_response)

      result = client.search_person('Shakespeare')

      expect(result.first[:viaf_id]).to be_a(Integer)
      expect(result.first[:viaf_id]).to eq(96994048)
    end

    it 'handles invalid JSON gracefully' do
      mock_response = double('response', success?: true, body: 'invalid json')
      allow(described_class).to receive(:get).and_return(mock_response)
      allow(Rails.logger).to receive(:error)

      result = client.search_person('Shakespeare')

      expect(result).to eq([])
      expect(Rails.logger).to have_received(:error).with(/VIAF API error/)
    end

    it 'URL encodes the query parameter' do
      allow(described_class).to receive(:get).and_return(
        double('response', success?: true, body: { 'result' => [] }.to_json)
      )

      client.search_person('Shakespeare, William')

      expect(described_class).to have_received(:get).with(
        a_string_matching(/Shakespeare%2C\+William/)
      )
    end
  end
end

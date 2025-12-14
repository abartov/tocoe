# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PersonMatcherService, type: :service do
  let(:query) { 'Douglas Adams' }
  let(:viaf_client) { instance_double(Viaf::Client) }
  let(:wikidata_client) { instance_double(SubjectHeadings::WikidataClient) }
  let(:loc_client) { instance_double(LibraryOfCongress::NameAuthorityClient) }

  before do
    allow(Viaf::Client).to receive(:new).and_return(viaf_client)
    allow(SubjectHeadings::WikidataClient).to receive(:new).and_return(wikidata_client)
    allow(LibraryOfCongress::NameAuthorityClient).to receive(:new).and_return(loc_client)
  end

  describe '.search_all' do
    context 'with a valid query' do
      let!(:person) { Person.create!(name: 'Douglas Adams', dates: '1952-2001', viaf_id: 113230702) }

      before do
        allow(viaf_client).to receive(:search_person).with(query).and_return([
          { viaf_id: 113230702, label: 'Adams, Douglas, 1952-2001' }
        ])

        allow(wikidata_client).to receive(:search).with(query, count: 20).and_return([
          {
            entity_id: 'Q42',
            label: 'Douglas Adams',
            description: 'English author and humorist',
            instance_of: ['human']
          }
        ])

        allow(loc_client).to receive(:search_person).with(query).and_return([
          { loc_id: 'n80076765', label: 'Adams, Douglas, 1952-2001' }
        ])
      end

      it 'returns results from all four sources' do
        results = described_class.search_all(query: query)

        expect(results).to have_key(:database)
        expect(results).to have_key(:viaf)
        expect(results).to have_key(:wikidata)
        expect(results).to have_key(:loc)
      end

      it 'includes database results' do
        results = described_class.search_all(query: query)

        expect(results[:database]).not_to be_empty
        expect(results[:database].first[:label]).to eq('Douglas Adams')
        expect(results[:database].first[:in_database]).to be true
      end

      it 'includes VIAF results' do
        results = described_class.search_all(query: query)

        expect(results[:viaf]).not_to be_empty
        expect(results[:viaf].first[:id]).to eq(113230702)
        expect(results[:viaf].first[:in_database]).to be true # Person exists with this VIAF ID
      end

      it 'includes Wikidata results (only humans)' do
        results = described_class.search_all(query: query)

        expect(results[:wikidata]).not_to be_empty
        expect(results[:wikidata].first[:id]).to eq(42)
        expect(results[:wikidata].first[:label]).to eq('Douglas Adams')
      end

      it 'includes Library of Congress results' do
        results = described_class.search_all(query: query)

        expect(results[:loc]).not_to be_empty
        expect(results[:loc].first[:id]).to eq('n80076765')
      end

      it 'marks candidates correctly' do
        candidates = [{ source: 'viaf', id: '113230702', label: 'Adams, Douglas' }]
        results = described_class.search_all(query: query, candidates: candidates)

        viaf_result = results[:viaf].first
        expect(viaf_result[:is_candidate]).to be true
      end

      it 'sorts results with candidates first' do
        allow(viaf_client).to receive(:search_person).with(query).and_return([
          { viaf_id: 999999, label: 'Adams, Douglas M.' },
          { viaf_id: 113230702, label: 'Adams, Douglas, 1952-2001' }
        ])

        candidates = [{ source: 'viaf', id: '113230702', label: 'Adams, Douglas' }]
        results = described_class.search_all(query: query, candidates: candidates)

        expect(results[:viaf].first[:is_candidate]).to be true
        expect(results[:viaf].first[:id]).to eq(113230702)
      end
    end

    context 'with a blank query' do
      it 'returns empty results' do
        results = described_class.search_all(query: '')

        expect(results[:database]).to be_empty
        expect(results[:viaf]).to be_empty
        expect(results[:wikidata]).to be_empty
        expect(results[:loc]).to be_empty
      end
    end
  end

  describe '.fetch_details' do
    context 'from database' do
      let!(:person) do
        Person.create!(
          name: 'Douglas Adams',
          dates: '1952-2001',
          country: 'United Kingdom',
          viaf_id: 113230702,
          wikidata_q: 42
        )
      end

      it 'returns detailed person information' do
        details = described_class.fetch_details(source: 'database', id: person.id)

        expect(details).to include(
          full_name: 'Douglas Adams',
          dates: '1952-2001',
          country: 'United Kingdom'
        )
        expect(details[:authority_ids]).to include(
          viaf: 113230702,
          wikidata: 42
        )
      end
    end

    context 'from wikidata' do
      before do
        # Mock the internal fetch_entities method
        allow(wikidata_client).to receive(:send).with(:fetch_entities, ['Q42']).and_return({
          'Q42' => {
            'claims' => {
              'P106' => [{ 'mainsnak' => { 'datavalue' => { 'value' => { 'id' => 'Q6625963' } } } }], # occupation
              'P569' => [{ 'mainsnak' => { 'datavalue' => { 'value' => { 'time' => '+1952-03-11T00:00:00Z' } } } }], # birth
              'P570' => [{ 'mainsnak' => { 'datavalue' => { 'value' => { 'time' => '+2001-05-11T00:00:00Z' } } } }], # death
              'P214' => [{ 'mainsnak' => { 'datavalue' => { 'value' => '113230702' } } }] # VIAF
            }
          }
        })

        allow(wikidata_client).to receive(:send).with(:fetch_labels, ['Q6625963']).and_return({
          'Q6625963' => 'novelist'
        })
      end

      it 'returns detailed information from Wikidata' do
        details = described_class.fetch_details(source: 'wikidata', id: 42)

        expect(details).to include(wikidata_id: 'Q42')
        expect(details[:birth_date]).to eq('1952-03-11')
        expect(details[:death_date]).to eq('2001-05-11')
        expect(details[:authority_ids][:viaf]).to eq('113230702')
      end
    end
  end

  describe '.match' do
    let!(:person) { Person.create!(name: 'Douglas Adams', dates: '1952-2001') }
    let!(:toc) { Toc.create!(book_uri: 'test_uri', status: 'empty') }

    context 'with existing person' do
      it 'associates person with Toc' do
        result = described_class.match(
          target_type: 'Toc',
          target_id: toc.id,
          source: 'database',
          external_id: person.id,
          person_id: person.id
        )

        expect(result[:success]).to be true
        expect(result[:person]).to eq(person)
        expect(person.tocs).to include(toc)
      end

      it 'does not create duplicate associations' do
        described_class.match(
          target_type: 'Toc',
          target_id: toc.id,
          source: 'database',
          external_id: person.id,
          person_id: person.id
        )

        expect {
          described_class.match(
            target_type: 'Toc',
            target_id: toc.id,
            source: 'database',
            external_id: person.id,
            person_id: person.id
          )
        }.not_to change(PeopleToc, :count)
      end
    end

    context 'creating new person from VIAF' do
      before do
        allow(viaf_client).to receive(:search_person).and_return([
          { viaf_id: 113230702, label: 'Adams, Douglas, 1952-2001' }
        ])
      end

      it 'creates a new person and associates it' do
        # Create a service instance with query context
        service = described_class.new(query: 'Douglas Adams')
        allow(described_class).to receive(:new).and_return(service)

        result = described_class.match(
          target_type: 'Toc',
          target_id: toc.id,
          source: 'viaf',
          external_id: '113230702',
          person_id: nil
        )

        expect(result[:success]).to be true
        expect(result[:person]).to be_persisted
        expect(result[:person].viaf_id).to eq(113230702)
      end
    end

    context 'with invalid target' do
      it 'returns error for non-existent target' do
        result = described_class.match(
          target_type: 'Toc',
          target_id: 999999,
          source: 'database',
          external_id: person.id,
          person_id: person.id
        )

        expect(result[:success]).to be false
        expect(result[:error]).to be_present
      end
    end
  end

  describe 'private methods' do
    let(:service) { described_class.new(query: query) }

    describe '#extract_dates_from_label' do
      it 'extracts dates from VIAF-style label' do
        dates = service.send(:extract_dates_from_label, 'Adams, Douglas, 1952-2001')
        expect(dates).to eq('1952-2001')
      end

      it 'extracts dates with "present"' do
        dates = service.send(:extract_dates_from_label, 'Adams, Douglas, 1952-present')
        expect(dates).to eq('1952-present')
      end

      it 'returns nil for label without dates' do
        dates = service.send(:extract_dates_from_label, 'Adams, Douglas')
        expect(dates).to be_nil
      end
    end

    describe '#format_wikidata_dates' do
      it 'formats birth and death dates' do
        dates = service.send(:format_wikidata_dates, '1952-03-11', '2001-05-11')
        expect(dates).to eq('1952-2001')
      end

      it 'formats birth date only' do
        dates = service.send(:format_wikidata_dates, '1952-03-11', nil)
        expect(dates).to eq('1952-present')
      end

      it 'returns nil for no dates' do
        dates = service.send(:format_wikidata_dates, nil, nil)
        expect(dates).to be_nil
      end
    end
  end
end

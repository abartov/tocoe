require 'rails_helper'

RSpec.describe 'Person Matching Integration', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

  before do
    sign_in user
  end

  describe 'POST /people/search_all' do
    it 'searches across all sources successfully' do
      # Stub external API calls
      allow_any_instance_of(Viaf::Client).to receive(:search_person).and_return([])
      allow_any_instance_of(SubjectHeadings::WikidataClient).to receive(:search).and_return([])
      allow_any_instance_of(LibraryOfCongress::NameAuthorityClient).to receive(:search_person).and_return([])

      post '/people/search_all', params: {
        query: 'Douglas Adams',
        candidates: []
      }, headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('database')
      expect(json).to have_key('viaf')
      expect(json).to have_key('wikidata')
      expect(json).to have_key('loc')
    end

    it 'handles empty query gracefully' do
      post '/people/search_all', params: {
        query: '',
        candidates: []
      }, headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['database']).to eq([])
      expect(json['viaf']).to eq([])
    end
  end

  describe 'POST /people/match' do
    let(:work) { Work.create!(title: 'Test Work') }
    let(:expression) { Expression.create!(title: 'Test Expression') }

    before do
      work.expressions << expression
    end

    context 'matching to a Work (author)' do
      it 'links existing Person to Work from database source' do
        person = Person.create!(name: 'Existing Author')

        expect {
          post '/people/match', params: {
            target_type: 'Work',
            target_id: work.id,
            source: 'database',
            external_id: person.id.to_s,
            person_id: person.id
          }, headers: { 'Accept' => 'application/json' }
        }.to change(Person, :count).by(0).and change(PeopleWork, :count).by(1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true

        work.reload
        expect(work.creators).to include(person)
      end

      it 'prevents duplicate associations' do
        person = Person.create!(name: 'Author')
        PeopleWork.create!(person: person, work: work)

        expect {
          post '/people/match', params: {
            target_type: 'Work',
            target_id: work.id,
            source: 'database',
            external_id: person.id.to_s,
            person_id: person.id
          }, headers: { 'Accept' => 'application/json' }
        }.to change(PeopleWork, :count).by(0)

        expect(response).to have_http_status(:success)
      end
    end

    context 'matching to an Expression (translator)' do
      it 'links existing Person to Expression from database source' do
        person = Person.create!(name: 'Existing Translator')

        expect {
          post '/people/match', params: {
            target_type: 'Expression',
            target_id: expression.id,
            source: 'database',
            external_id: person.id.to_s,
            person_id: person.id
          }, headers: { 'Accept' => 'application/json' }
        }.to change(Person, :count).by(0).and change(Realization, :count).by(1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true

        expression.reload
        expect(expression.realizers).to include(person)
      end

      it 'prevents duplicate realizations' do
        person = Person.create!(name: 'Translator')
        Realization.create!(realizer: person, expression: expression)

        expect {
          post '/people/match', params: {
            target_type: 'Expression',
            target_id: expression.id,
            source: 'database',
            external_id: person.id.to_s,
            person_id: person.id
          }, headers: { 'Accept' => 'application/json' }
        }.to change(Realization, :count).by(0)

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'Full review_authors workflow with person matching', :js do
    it 'allows matching authors through the complete workflow' do
      # This test verifies the entire flow works but requires JS
      # Skipping for now as it requires Selenium/Capybara JS driver
      skip 'Requires JS driver for full integration test'
    end
  end
end

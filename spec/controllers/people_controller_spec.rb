require 'rails_helper'

RSpec.describe PeopleController, type: :controller do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:person) { Person.create!(name: 'Test Author', dates: '1564-1616') }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'assigns all people ordered by name' do
      person1 = Person.create!(name: 'Zoe Author')
      person2 = Person.create!(name: 'Alice Author')
      person3 = Person.create!(name: 'Bob Author')

      get :index

      expect(assigns(:people)).to eq([person2, person3, person1])
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end

    it 'requires authentication' do
      sign_out user
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET #show' do
    it 'assigns the requested person' do
      get :show, params: { id: person.id }
      expect(assigns(:person)).to eq(person)
    end

    it 'renders the show template' do
      get :show, params: { id: person.id }
      expect(response).to render_template(:show)
    end

    it 'requires authentication' do
      sign_out user
      get :show, params: { id: person.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET #new' do
    it 'assigns a new person' do
      get :new
      expect(assigns(:person)).to be_a_new(Person)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end

    it 'requires authentication' do
      sign_out user
      get :new
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new person' do
        expect {
          post :create, params: { person: { name: 'New Author', dates: '1800-1900' } }
        }.to change(Person, :count).by(1)
      end

      it 'redirects to the person show page' do
        post :create, params: { person: { name: 'New Author' } }
        expect(response).to redirect_to(Person.last)
      end

      it 'sets a success flash message' do
        post :create, params: { person: { name: 'New Author' } }
        expect(flash[:notice]).to eq(I18n.t('people.flash.created_successfully'))
      end

      it 'saves all permitted attributes' do
        post :create, params: {
          person: {
            name: 'New Author',
            dates: '1800-1900',
            title: 'Dr.',
            affiliation: 'University',
            country: 'USA',
            comment: 'Test comment',
            viaf_id: 12345678,
            wikidata_q: 87654321,
            openlibrary_id: '/authors/OL123A',
            loc_id: 'n79021164',
            gutenberg_id: 4527
          }
        }

        created_person = Person.last
        expect(created_person.name).to eq('New Author')
        expect(created_person.dates).to eq('1800-1900')
        expect(created_person.title).to eq('Dr.')
        expect(created_person.affiliation).to eq('University')
        expect(created_person.country).to eq('USA')
        expect(created_person.comment).to eq('Test comment')
        expect(created_person.viaf_id).to eq(12345678)
        expect(created_person.wikidata_q).to eq(87654321)
        expect(created_person.openlibrary_id).to eq('/authors/OL123A')
        expect(created_person.loc_id).to eq('n79021164')
        expect(created_person.gutenberg_id).to eq(4527)
      end
    end

    context 'with invalid attributes' do
      it 'does not create a new person' do
        expect {
          post :create, params: { person: { name: '' } }
        }.not_to change(Person, :count)
      end

      it 'renders the new template' do
        post :create, params: { person: { name: '' } }
        expect(response).to render_template(:new)
      end

      it 'returns unprocessable entity status' do
        post :create, params: { person: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it 'requires authentication' do
      sign_out user
      post :create, params: { person: { name: 'New Author' } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested person' do
      get :edit, params: { id: person.id }
      expect(assigns(:person)).to eq(person)
    end

    it 'renders the edit template' do
      get :edit, params: { id: person.id }
      expect(response).to render_template(:edit)
    end

    it 'requires authentication' do
      sign_out user
      get :edit, params: { id: person.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'PATCH #update' do
    context 'with valid attributes' do
      it 'updates the person' do
        patch :update, params: { id: person.id, person: { name: 'Updated Author' } }
        person.reload
        expect(person.name).to eq('Updated Author')
      end

      it 'redirects to the person show page' do
        patch :update, params: { id: person.id, person: { name: 'Updated Author' } }
        expect(response).to redirect_to(person)
      end

      it 'sets a success flash message' do
        patch :update, params: { id: person.id, person: { name: 'Updated Author' } }
        expect(flash[:notice]).to eq(I18n.t('people.flash.updated_successfully'))
      end

      it 'updates all permitted attributes' do
        patch :update, params: {
          id: person.id,
          person: {
            name: 'Updated Author',
            dates: '1900-2000',
            title: 'Prof.',
            affiliation: 'College',
            country: 'UK',
            comment: 'Updated comment',
            viaf_id: 11111111,
            wikidata_q: 22222222,
            openlibrary_id: '/authors/OL999Z',
            loc_id: 'n99999999',
            gutenberg_id: 9999
          }
        }

        person.reload
        expect(person.name).to eq('Updated Author')
        expect(person.dates).to eq('1900-2000')
        expect(person.title).to eq('Prof.')
        expect(person.affiliation).to eq('College')
        expect(person.country).to eq('UK')
        expect(person.comment).to eq('Updated comment')
        expect(person.viaf_id).to eq(11111111)
        expect(person.wikidata_q).to eq(22222222)
        expect(person.openlibrary_id).to eq('/authors/OL999Z')
        expect(person.loc_id).to eq('n99999999')
        expect(person.gutenberg_id).to eq(9999)
      end
    end

    context 'with invalid attributes' do
      it 'does not update the person' do
        patch :update, params: { id: person.id, person: { name: '' } }
        person.reload
        expect(person.name).to eq('Test Author')
      end

      it 'renders the edit template' do
        patch :update, params: { id: person.id, person: { name: '' } }
        expect(response).to render_template(:edit)
      end

      it 'returns unprocessable entity status' do
        patch :update, params: { id: person.id, person: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it 'requires authentication' do
      sign_out user
      patch :update, params: { id: person.id, person: { name: 'Updated Author' } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  # Tests for person matcher endpoints
  describe 'POST #search_all' do
    let(:search_results) do
      {
        database: [{ id: 1, label: 'Douglas Adams', in_database: true }],
        viaf: [{ id: 113230702, label: 'Adams, Douglas, 1952-2001', in_database: false }],
        wikidata: [{ id: 42, label: 'Douglas Adams', in_database: false }],
        loc: [{ id: 'n80076765', label: 'Adams, Douglas, 1952-2001', in_database: false }]
      }
    end

    before do
      allow(PersonMatcherService).to receive(:search_all).and_return(search_results)
    end

    it 'returns results from all sources' do
      post :search_all, params: { query: 'Douglas Adams' }, format: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body, symbolize_names: true)

      expect(json).to have_key(:database)
      expect(json).to have_key(:viaf)
      expect(json).to have_key(:wikidata)
      expect(json).to have_key(:loc)
    end

    it 'passes query and candidates to service' do
      candidates = [{ source: 'viaf', id: '113230702', label: 'Adams, Douglas' }]

      # Rails wraps params in ActionController::Parameters, so we need to match that
      expect(PersonMatcherService).to receive(:search_all) do |args|
        expect(args[:query]).to eq('Douglas Adams')
        expect(args[:candidates].size).to eq(1)
        expect(args[:candidates].first).to be_a(ActionController::Parameters)
        search_results
      end

      post :search_all, params: { query: 'Douglas Adams', candidates: candidates }, format: :json
    end

    it 'handles empty candidates array' do
      expect(PersonMatcherService).to receive(:search_all).with(
        query: 'Douglas Adams',
        candidates: []
      ).and_return(search_results)

      post :search_all, params: { query: 'Douglas Adams' }, format: :json
    end

    it 'requires authentication' do
      sign_out user
      post :search_all, params: { query: 'Douglas Adams' }, format: :json
      # JSON requests return 401 instead of redirect
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET #fetch_details' do
    let(:details) do
      {
        full_name: 'Douglas Noël Adams',
        dates: '1952-2001',
        country: 'United Kingdom',
        authority_ids: { viaf: 113230702, wikidata: 42 }
      }
    end

    context 'when details are found' do
      before do
        allow(PersonMatcherService).to receive(:fetch_details).and_return(details)
      end

      it 'returns detailed information' do
        get :fetch_details, params: { source: 'database', id: 1 }, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body, symbolize_names: true)

        expect(json[:full_name]).to eq('Douglas Noël Adams')
        expect(json[:dates]).to eq('1952-2001')
      end

      it 'passes source and id to service' do
        expect(PersonMatcherService).to receive(:fetch_details).with(
          source: 'viaf',
          id: '113230702'
        ).and_return(details)

        get :fetch_details, params: { source: 'viaf', id: '113230702' }, format: :json
      end
    end

    context 'when details are not found' do
      before do
        allow(PersonMatcherService).to receive(:fetch_details).and_return(nil)
      end

      it 'returns 404 status' do
        get :fetch_details, params: { source: 'database', id: 999 }, format: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:error]).to eq('Details not found')
      end
    end

    it 'requires authentication' do
      sign_out user
      get :fetch_details, params: { source: 'database', id: 1 }, format: :json
      # JSON requests return 401 instead of redirect
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #match' do
    let(:toc) { Toc.create!(book_uri: 'test_uri', status: 'empty') }

    context 'when matching succeeds' do
      before do
        allow(PersonMatcherService).to receive(:match).and_return(
          { success: true, person: person }
        )
      end

      it 'returns success response' do
        post :match, params: {
          target_type: 'Toc',
          target_id: toc.id,
          source: 'database',
          external_id: person.id,
          person_id: person.id
        }, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:success]).to be true
      end

      it 'passes all parameters to service' do
        expect(PersonMatcherService).to receive(:match).with(
          target_type: 'Toc',
          target_id: toc.id.to_s,
          source: 'database',
          external_id: person.id.to_s,
          person_id: person.id.to_s
        ).and_return({ success: true, person: person })

        post :match, params: {
          target_type: 'Toc',
          target_id: toc.id,
          source: 'database',
          external_id: person.id,
          person_id: person.id
        }, format: :json
      end
    end

    context 'when matching fails' do
      before do
        allow(PersonMatcherService).to receive(:match).and_return(
          { success: false, error: 'Failed to create association' }
        )
      end

      it 'returns error response with 422 status' do
        post :match, params: {
          target_type: 'Toc',
          target_id: 999,
          source: 'database',
          external_id: person.id,
          person_id: person.id
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:success]).to be false
        expect(json[:error]).to be_present
      end
    end

    it 'requires authentication' do
      sign_out user
      post :match, params: {
        target_type: 'Toc',
        target_id: toc.id,
        source: 'database',
        external_id: person.id,
        person_id: person.id
      }, format: :json
      # JSON requests return 401 instead of redirect
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #accept_parent_match' do
    let(:work) { Work.create!(title: 'Test Work') }
    let(:toc_author) { Person.create!(name: 'TOC Author', dates: '1800-1900') }

    context 'when matching an author to a work' do
      it 'creates a work-person association' do
        expect {
          post :accept_parent_match, params: {
            work_id: work.id,
            person_id: toc_author.id,
            role: 'author'
          }, format: :json
        }.to change(PeopleWork, :count).by(1)

        # Verify the association was created
        expect(work.reload.creators).to include(toc_author)
      end

      it 'returns success response' do
        post :accept_parent_match, params: {
          work_id: work.id,
          person_id: toc_author.id,
          role: 'author'
        }, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:success]).to be true
        expect(json[:person][:id]).to eq(toc_author.id)
        expect(json[:person][:name]).to eq('TOC Author')
      end

      it 'does not create duplicate associations' do
        # Create initial association
        PeopleWork.create!(person: toc_author, work: work)

        # Try to create it again
        expect {
          post :accept_parent_match, params: {
            work_id: work.id,
            person_id: toc_author.id,
            role: 'author'
          }, format: :json
        }.not_to change(PeopleWork, :count)

        # Should still return success
        expect(response).to have_http_status(:success)
      end
    end

    context 'when matching a translator to an expression' do
      let(:expression) { Expression.create!(work: work, title: 'Test Expression') }

      before do
        # Ensure the work has an expression
        expression
      end

      it 'creates an expression-person realization' do
        expect {
          post :accept_parent_match, params: {
            work_id: work.id,
            person_id: toc_author.id,
            role: 'translator'
          }, format: :json
        }.to change(Realization, :count).by(1)

        # Verify the realization was created
        expect(work.reload.expressions.first.realizers).to include(toc_author)
      end

      it 'returns success response for translator' do
        post :accept_parent_match, params: {
          work_id: work.id,
          person_id: toc_author.id,
          role: 'translator'
        }, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:success]).to be true
      end
    end

    context 'with missing parameters' do
      it 'returns error when work_id is missing' do
        post :accept_parent_match, params: {
          person_id: toc_author.id,
          role: 'author'
        }, format: :json

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:success]).to be false
        expect(json[:error]).to eq('Missing required parameters')
      end

      it 'returns error when person_id is missing' do
        post :accept_parent_match, params: {
          work_id: work.id,
          role: 'author'
        }, format: :json

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:success]).to be false
        expect(json[:error]).to eq('Missing required parameters')
      end
    end

    context 'with invalid IDs' do
      it 'returns error when work is not found' do
        post :accept_parent_match, params: {
          work_id: 99999,
          person_id: toc_author.id,
          role: 'author'
        }, format: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:success]).to be false
        expect(json[:error]).to eq('Work or Person not found')
      end

      it 'returns error when person is not found' do
        post :accept_parent_match, params: {
          work_id: work.id,
          person_id: 99999,
          role: 'author'
        }, format: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:success]).to be false
        expect(json[:error]).to eq('Work or Person not found')
      end
    end

    context 'when translator role but no expression exists' do
      it 'returns error when work has no expressions' do
        # Ensure work has no expressions
        work.expressions.destroy_all

        post :accept_parent_match, params: {
          work_id: work.id,
          person_id: toc_author.id,
          role: 'translator'
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:success]).to be false
        expect(json[:error]).to eq('Failed to create association')
      end
    end

    context 'when role is not specified' do
      it 'defaults to author role' do
        expect {
          post :accept_parent_match, params: {
            work_id: work.id,
            person_id: toc_author.id
          }, format: :json
        }.to change(PeopleWork, :count).by(1)

        expect(work.reload.creators).to include(toc_author)
      end
    end

    it 'requires authentication' do
      sign_out user
      post :accept_parent_match, params: {
        work_id: work.id,
        person_id: toc_author.id,
        role: 'author'
      }, format: :json
      # JSON requests return 401 instead of redirect
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

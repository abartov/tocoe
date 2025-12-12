require 'rails_helper'

RSpec.describe AboutnessesController, type: :controller do
  render_views false

  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:expression) { Expression.create!(title: "Test Expression") }
  let(:manifestation) { Manifestation.create!(title: "Test Manifestation") }
  let(:embodiment) { Embodiment.create!(expression: expression, manifestation: manifestation) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'assigns aboutnesses for the embodiment' do
      aboutness = Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'http://id.loc.gov/authorities/subjects/sh85146352',
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )

      get :index, params: { embodiment_id: embodiment.id }

      expect(assigns(:aboutnesses)).to include(aboutness)
      expect(response).to be_successful
    end
  end

  describe 'GET #new' do
    it 'assigns a new aboutness' do
      get :new, params: { embodiment_id: embodiment.id }

      expect(assigns(:aboutness)).to be_a_new(Aboutness)
      expect(response).to be_successful
    end
  end

  describe 'POST #search' do
    let(:mock_results) do
      [
        { uri: 'http://id.loc.gov/authorities/subjects/sh85146352', label: 'Whales' },
        { uri: 'http://id.loc.gov/authorities/subjects/sh85146353', label: 'Whales--Anatomy' }
      ]
    end

    context 'with LCSH source' do
      it 'searches using LCSH client and returns JSON' do
        lcsh_client = instance_double(SubjectHeadings::LcshClient)
        allow(SubjectHeadings::LcshClient).to receive(:new).and_return(lcsh_client)
        allow(lcsh_client).to receive(:search).with('whales').and_return(mock_results)

        post :search, params: { embodiment_id: embodiment.id, source: 'LCSH', query: 'whales' }, format: :json

        expect(response).to be_successful
        expect(JSON.parse(response.body)).to eq(mock_results.map(&:stringify_keys))
      end
    end

    context 'with Wikidata source' do
      it 'searches using Wikidata client and returns JSON' do
        wikidata_client = instance_double(SubjectHeadings::WikidataClient)
        allow(SubjectHeadings::WikidataClient).to receive(:new).and_return(wikidata_client)
        allow(wikidata_client).to receive(:search).with('Douglas Adams').and_return(mock_results)

        post :search, params: { embodiment_id: embodiment.id, source: 'Wikidata', query: 'Douglas Adams' }, format: :json

        expect(response).to be_successful
        expect(JSON.parse(response.body)).to eq(mock_results.map(&:stringify_keys))
      end
    end

    context 'with invalid source' do
      it 'returns an empty array' do
        post :search, params: { embodiment_id: embodiment.id, source: 'InvalidSource', query: 'test' }, format: :json

        expect(response).to be_successful
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          embodiment_id: embodiment.id,
          aboutness: {
            subject_heading_uri: 'http://id.loc.gov/authorities/subjects/sh85146352',
            source_name: 'LCSH',
            subject_heading_label: 'Whales'
          }
        }
      end

      before do
        # Stub WikidataClient to prevent SPARQL queries in these basic tests
        wikidata_client = instance_double(SubjectHeadings::WikidataClient)
        allow(SubjectHeadings::WikidataClient).to receive(:new).and_return(wikidata_client)
        allow(wikidata_client).to receive(:find_entity_by_library_of_congress_id).and_return(nil)
      end

      it 'creates a new aboutness' do
        expect {
          post :create, params: valid_params
        }.to change(Aboutness, :count).by(1)
      end

      it 'redirects to the aboutnesses index' do
        post :create, params: valid_params

        expect(response).to redirect_to(embodiment_aboutnesses_path(embodiment))
      end

      it 'sets contributor_id to current user' do
        post :create, params: valid_params

        aboutness = Aboutness.last
        expect(aboutness.contributor_id).to eq(user.id)
      end

      it 'sets status to proposed for user-contributed aboutnesses' do
        post :create, params: valid_params

        aboutness = Aboutness.last
        expect(aboutness.status).to eq('proposed')
      end
    end

    context 'when creating a Wikidata aboutness with P244' do
      let(:wikidata_params) do
        {
          embodiment_id: embodiment.id,
          aboutness: {
            subject_heading_uri: 'http://www.wikidata.org/entity/Q395',
            source_name: 'Wikidata',
            subject_heading_label: 'mathematics'
          }
        }
      end

      let(:wikidata_client) { instance_double(SubjectHeadings::WikidataClient) }

      before do
        allow(SubjectHeadings::WikidataClient).to receive(:new).and_return(wikidata_client)
      end

      context 'when the Wikidata entity has a Library of Congress ID' do
        before do
          allow(wikidata_client).to receive(:get_library_of_congress_id).with('Q395').and_return('sh85082139')
        end

        it 'creates both Wikidata and LC aboutnesses' do
          expect {
            post :create, params: wikidata_params
          }.to change(Aboutness, :count).by(2)
        end

        it 'creates an LC aboutness with the correct URI' do
          post :create, params: wikidata_params

          lc_aboutness = Aboutness.find_by(source_name: 'LCSH')
          expect(lc_aboutness).to be_present
          expect(lc_aboutness.subject_heading_uri).to eq('https://id.loc.gov/authorities/subjects/sh85082139')
        end

        it 'sets the same status for both aboutnesses' do
          post :create, params: wikidata_params

          wikidata_aboutness = Aboutness.find_by(source_name: 'Wikidata')
          lc_aboutness = Aboutness.find_by(source_name: 'LCSH')
          expect(wikidata_aboutness.status).to eq('proposed')
          expect(lc_aboutness.status).to eq('proposed')
        end

        it 'sets the same contributor for both aboutnesses' do
          post :create, params: wikidata_params

          wikidata_aboutness = Aboutness.find_by(source_name: 'Wikidata')
          lc_aboutness = Aboutness.find_by(source_name: 'LCSH')
          expect(wikidata_aboutness.contributor_id).to eq(user.id)
          expect(lc_aboutness.contributor_id).to eq(user.id)
        end

        it 'uses the same label for both aboutnesses' do
          post :create, params: wikidata_params

          wikidata_aboutness = Aboutness.find_by(source_name: 'Wikidata')
          lc_aboutness = Aboutness.find_by(source_name: 'LCSH')
          expect(wikidata_aboutness.subject_heading_label).to eq('mathematics')
          expect(lc_aboutness.subject_heading_label).to eq('mathematics')
        end

        context 'when LC aboutness already exists' do
          before do
            Aboutness.create!(
              embodiment: embodiment,
              subject_heading_uri: 'https://id.loc.gov/authorities/subjects/sh85082139',
              source_name: 'LCSH',
              subject_heading_label: 'Mathematics'
            )
          end

          it 'only creates the Wikidata aboutness' do
            expect {
              post :create, params: wikidata_params
            }.to change(Aboutness, :count).by(1)
          end

          it 'does not create a duplicate LC aboutness' do
            post :create, params: wikidata_params

            lc_aboutnesses = Aboutness.where(
              embodiment: embodiment,
              subject_heading_uri: 'https://id.loc.gov/authorities/subjects/sh85082139'
            )
            expect(lc_aboutnesses.count).to eq(1)
          end
        end
      end

      context 'when the Wikidata entity does not have a Library of Congress ID' do
        before do
          allow(wikidata_client).to receive(:get_library_of_congress_id).with('Q395').and_return(nil)
        end

        it 'only creates the Wikidata aboutness' do
          expect {
            post :create, params: wikidata_params
          }.to change(Aboutness, :count).by(1)
        end

        it 'does not create an LC aboutness' do
          post :create, params: wikidata_params

          lc_aboutness = Aboutness.find_by(source_name: 'LCSH')
          expect(lc_aboutness).to be_nil
        end
      end

      context 'when there is an error fetching the LC ID' do
        before do
          allow(wikidata_client).to receive(:get_library_of_congress_id).and_raise(StandardError.new('API error'))
        end

        it 'still creates the Wikidata aboutness' do
          expect {
            post :create, params: wikidata_params
          }.to change(Aboutness, :count).by(1)
        end

        it 'logs the error' do
          expect(Rails.logger).to receive(:error).with(/Error auto-adding LC subject heading/)
          post :create, params: wikidata_params
        end
      end
    end

    context 'when creating an LCSH aboutness with matching Wikidata entity' do
      let(:lcsh_params) do
        {
          embodiment_id: embodiment.id,
          aboutness: {
            subject_heading_uri: 'https://id.loc.gov/authorities/subjects/sh85082139',
            source_name: 'LCSH',
            subject_heading_label: 'Mathematics'
          }
        }
      end

      let(:wikidata_client) { instance_double(SubjectHeadings::WikidataClient) }

      before do
        allow(SubjectHeadings::WikidataClient).to receive(:new).and_return(wikidata_client)
      end

      context 'when Wikidata has an entity with this P244 value' do
        before do
          allow(wikidata_client).to receive(:find_entity_by_library_of_congress_id)
            .with('sh85082139')
            .and_return({ entity_id: 'Q395', label: 'mathematics' })
        end

        it 'creates both LCSH and Wikidata aboutnesses' do
          expect {
            post :create, params: lcsh_params
          }.to change(Aboutness, :count).by(2)
        end

        it 'creates a Wikidata aboutness with the correct URI' do
          post :create, params: lcsh_params

          wikidata_aboutness = Aboutness.find_by(source_name: 'Wikidata')
          expect(wikidata_aboutness).to be_present
          expect(wikidata_aboutness.subject_heading_uri).to eq('http://www.wikidata.org/entity/Q395')
        end

        it 'uses the label from Wikidata' do
          post :create, params: lcsh_params

          wikidata_aboutness = Aboutness.find_by(source_name: 'Wikidata')
          expect(wikidata_aboutness.subject_heading_label).to eq('mathematics')
        end

        it 'sets the same status for both aboutnesses' do
          post :create, params: lcsh_params

          lcsh_aboutness = Aboutness.find_by(source_name: 'LCSH')
          wikidata_aboutness = Aboutness.find_by(source_name: 'Wikidata')
          expect(lcsh_aboutness.status).to eq('proposed')
          expect(wikidata_aboutness.status).to eq('proposed')
        end

        it 'sets the same contributor for both aboutnesses' do
          post :create, params: lcsh_params

          lcsh_aboutness = Aboutness.find_by(source_name: 'LCSH')
          wikidata_aboutness = Aboutness.find_by(source_name: 'Wikidata')
          expect(lcsh_aboutness.contributor_id).to eq(user.id)
          expect(wikidata_aboutness.contributor_id).to eq(user.id)
        end

        context 'when Wikidata aboutness already exists' do
          before do
            Aboutness.create!(
              embodiment: embodiment,
              subject_heading_uri: 'http://www.wikidata.org/entity/Q395',
              source_name: 'Wikidata',
              subject_heading_label: 'mathematics'
            )
          end

          it 'only creates the LCSH aboutness' do
            expect {
              post :create, params: lcsh_params
            }.to change(Aboutness, :count).by(1)
          end

          it 'does not create a duplicate Wikidata aboutness' do
            post :create, params: lcsh_params

            wikidata_aboutnesses = Aboutness.where(
              embodiment: embodiment,
              subject_heading_uri: 'http://www.wikidata.org/entity/Q395'
            )
            expect(wikidata_aboutnesses.count).to eq(1)
          end
        end
      end

      context 'when Wikidata does not have an entity with this P244 value' do
        before do
          allow(wikidata_client).to receive(:find_entity_by_library_of_congress_id)
            .with('sh85082139')
            .and_return(nil)
        end

        it 'only creates the LCSH aboutness' do
          expect {
            post :create, params: lcsh_params
          }.to change(Aboutness, :count).by(1)
        end

        it 'does not create a Wikidata aboutness' do
          post :create, params: lcsh_params

          wikidata_aboutness = Aboutness.find_by(source_name: 'Wikidata')
          expect(wikidata_aboutness).to be_nil
        end
      end

      context 'when there is an error searching Wikidata' do
        before do
          allow(wikidata_client).to receive(:find_entity_by_library_of_congress_id)
            .and_raise(StandardError.new('SPARQL error'))
        end

        it 'still creates the LCSH aboutness' do
          expect {
            post :create, params: lcsh_params
          }.to change(Aboutness, :count).by(1)
        end

        it 'logs the error' do
          expect(Rails.logger).to receive(:error).with(/Error auto-adding Wikidata heading/)
          post :create, params: lcsh_params
        end
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          embodiment_id: embodiment.id,
          aboutness: {
            subject_heading_uri: '',
            source_name: 'LCSH',
            subject_heading_label: ''
          }
        }
      end

      it 'does not create a new aboutness' do
        expect {
          post :create, params: invalid_params
        }.not_to change(Aboutness, :count)
      end

      it 'returns an unsuccessful response' do
        post :create, params: invalid_params

        expect(response).not_to be_redirect
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:aboutness) do
      Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'http://id.loc.gov/authorities/subjects/sh85146352',
        source_name: 'LCSH',
        subject_heading_label: 'Whales'
      )
    end

    it 'destroys the aboutness' do
      expect {
        delete :destroy, params: { id: aboutness.id }
      }.to change(Aboutness, :count).by(-1)
    end

    it 'redirects to the aboutnesses index' do
      delete :destroy, params: { id: aboutness.id }

      expect(response).to redirect_to(embodiment_aboutnesses_path(embodiment))
    end
  end

  describe 'PATCH #verify' do
    let(:contributor) { User.create!(email: 'contributor@example.com', password: 'password123', password_confirmation: 'password123') }
    let(:reviewer) { User.create!(email: 'reviewer@example.com', password: 'password123', password_confirmation: 'password123') }

    context 'when verifying a proposed aboutness contributed by another user' do
      let!(:aboutness) do
        Aboutness.create!(
          embodiment: embodiment,
          subject_heading_uri: 'http://id.loc.gov/authorities/subjects/sh85146352',
          source_name: 'LCSH',
          subject_heading_label: 'Whales',
          contributor: contributor,
          status: 'proposed'
        )
      end

      before do
        sign_in reviewer
      end

      it 'verifies the aboutness' do
        patch :verify, params: { id: aboutness.id }

        aboutness.reload
        expect(aboutness.status).to eq('verified')
      end

      it 'sets the reviewer_id to current user' do
        patch :verify, params: { id: aboutness.id }

        aboutness.reload
        expect(aboutness.reviewer_id).to eq(reviewer.id)
      end

      it 'redirects to the aboutnesses index with success notice' do
        patch :verify, params: { id: aboutness.id }

        expect(response).to redirect_to(embodiment_aboutnesses_path(embodiment))
        expect(flash[:notice]).to eq('Subject heading was successfully verified.')
      end
    end

    context 'when trying to verify own contribution' do
      let!(:aboutness) do
        Aboutness.create!(
          embodiment: embodiment,
          subject_heading_uri: 'http://id.loc.gov/authorities/subjects/sh85146352',
          source_name: 'LCSH',
          subject_heading_label: 'Whales',
          contributor: user,
          status: 'proposed'
        )
      end

      it 'does not verify the aboutness' do
        patch :verify, params: { id: aboutness.id }

        aboutness.reload
        expect(aboutness.status).to eq('proposed')
      end

      it 'redirects with alert message' do
        patch :verify, params: { id: aboutness.id }

        expect(response).to redirect_to(embodiment_aboutnesses_path(embodiment))
        expect(flash[:alert]).to eq('You cannot verify this subject heading.')
      end
    end

    context 'when trying to verify an already verified aboutness' do
      let!(:aboutness) do
        Aboutness.create!(
          embodiment: embodiment,
          subject_heading_uri: 'http://id.loc.gov/authorities/subjects/sh85146352',
          source_name: 'LCSH',
          subject_heading_label: 'Whales',
          status: 'verified'
        )
      end

      it 'does not change the status' do
        original_status = aboutness.status
        patch :verify, params: { id: aboutness.id }

        aboutness.reload
        expect(aboutness.status).to eq(original_status)
      end

      it 'redirects with alert message' do
        patch :verify, params: { id: aboutness.id }

        expect(response).to redirect_to(embodiment_aboutnesses_path(embodiment))
        expect(flash[:alert]).to eq('You cannot verify this subject heading.')
      end
    end
  end
end

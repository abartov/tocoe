require 'rails_helper'

RSpec.describe AboutnessesController, type: :controller do
  render_views false

  let(:expression) { Expression.create!(title: "Test Expression") }
  let(:manifestation) { Manifestation.create!(title: "Test Manifestation") }
  let(:embodiment) { Embodiment.create!(expression: expression, manifestation: manifestation) }

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

      it 'creates a new aboutness' do
        expect {
          post :create, params: valid_params
        }.to change(Aboutness, :count).by(1)
      end

      it 'redirects to the aboutnesses index' do
        post :create, params: valid_params

        expect(response).to redirect_to(embodiment_aboutnesses_path(embodiment))
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
end

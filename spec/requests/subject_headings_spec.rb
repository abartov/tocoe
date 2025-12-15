require 'rails_helper'

RSpec.describe "SubjectHeadings", type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    sign_in user
  end

  describe "GET /subject_headings" do
    context "when no aboutnesses exist" do
      it "returns http success" do
        get subject_headings_path
        expect(response).to have_http_status(:success)
      end

      it "shows empty state message" do
        get subject_headings_path
        expect(response.body).to include(I18n.t('subject_headings.index.no_aboutnesses'))
      end
    end

    context "when aboutnesses exist" do
      let!(:work) { Work.create!(title: 'Test Work') }
      let!(:expression) { Expression.create!(title: 'Test Expression') }
      let!(:manifestation) { Manifestation.create!(title: 'Test Manifestation') }
      let!(:embodiment) { Embodiment.create!(expression: expression, manifestation: manifestation) }
      let!(:reification) { Reification.create!(work: work, expression: expression) }

      let!(:aboutness1) do
        Aboutness.create!(
          embodiment: embodiment,
          subject_heading_uri: 'https://id.loc.gov/authorities/subjects/sh85082139',
          subject_heading_label: 'Mathematics',
          source_name: 'LCSH',
          status: 'verified'
        )
      end

      let!(:aboutness2) do
        Aboutness.create!(
          embodiment: embodiment,
          subject_heading_uri: 'http://www.wikidata.org/entity/Q395',
          subject_heading_label: 'Mathematics',
          source_name: 'Wikidata',
          status: 'proposed'
        )
      end

      it "returns http success" do
        get subject_headings_path
        expect(response).to have_http_status(:success)
      end

      it "displays correct statistics" do
        get subject_headings_path
        expect(response.body).to include('2') # total aboutnesses
        expect(response.body).to include('1') # verified
        expect(response.body).to include('1') # proposed
      end

      it "displays latest aboutnesses" do
        get subject_headings_path
        expect(response.body).to include('Mathematics')
        expect(response.body).to include('LCSH')
        expect(response.body).to include('Wikidata')
      end

      it "displays popular headings" do
        get subject_headings_path
        expect(response.body).to include(I18n.t('subject_headings.index.popular_title'))
      end
    end

    context "with search query" do
      let!(:work) { Work.create!(title: 'Test Work') }
      let!(:expression) { Expression.create!(title: 'Test Expression') }
      let!(:manifestation) { Manifestation.create!(title: 'Test Manifestation') }
      let!(:embodiment) { Embodiment.create!(expression: expression, manifestation: manifestation) }
      let!(:reification) { Reification.create!(work: work, expression: expression) }

      let!(:aboutness) do
        Aboutness.create!(
          embodiment: embodiment,
          subject_heading_uri: 'https://id.loc.gov/authorities/subjects/sh85082139',
          subject_heading_label: 'Mathematics',
          source_name: 'LCSH',
          status: 'verified'
        )
      end

      it "finds matching subject headings" do
        get subject_headings_path, params: { q: 'Math' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Mathematics')
      end
    end
  end

  describe "GET /subject_headings/:id" do
    let!(:work) { Work.create!(title: 'Test Work') }
    let!(:expression) { Expression.create!(title: 'Test Expression') }
    let!(:manifestation) { Manifestation.create!(title: 'Test Manifestation') }
    let!(:embodiment) { Embodiment.create!(expression: expression, manifestation: manifestation) }
    let!(:reification) { Reification.create!(work: work, expression: expression) }

    let!(:aboutness) do
      Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://id.loc.gov/authorities/subjects/sh85082139',
        subject_heading_label: 'Mathematics',
        source_name: 'LCSH',
        status: 'verified'
      )
    end

    it "returns http success for valid URI" do
      get subject_heading_path(Base64.urlsafe_encode64(aboutness.subject_heading_uri))
      expect(response).to have_http_status(:success)
    end

    it "displays subject heading details" do
      get subject_heading_path(Base64.urlsafe_encode64(aboutness.subject_heading_uri))
      expect(response.body).to include('Mathematics')
      expect(response.body).to include('LCSH')
      expect(response.body).to include(aboutness.subject_heading_uri)
    end

    it "displays statistics" do
      get subject_heading_path(Base64.urlsafe_encode64(aboutness.subject_heading_uri))
      expect(response.body).to include(I18n.t('subject_headings.show.statistics_title'))
      expect(response.body).to include(I18n.t('subject_headings.show.stats.total_links'))
    end

    it "displays linked works" do
      get subject_heading_path(Base64.urlsafe_encode64(aboutness.subject_heading_uri))
      expect(response.body).to include(I18n.t('subject_headings.show.linked_works_title'))
      expect(response.body).to include('Test Work')
    end

    it "redirects for non-existent URI" do
      get subject_heading_path(Base64.urlsafe_encode64('https://example.com/nonexistent'))
      expect(response).to redirect_to(subject_headings_path)
      follow_redirect!
      expect(response.body).to include('Subject heading not found')
    end

    it "displays external link for LCSH subjects" do
      get subject_heading_path(Base64.urlsafe_encode64(aboutness.subject_heading_uri))
      expect(response.body).to include(I18n.t('subject_headings.show.view_on_lcsh'))
    end

    context "with Wikidata subject" do
      let!(:wikidata_aboutness) do
        Aboutness.create!(
          embodiment: embodiment,
          subject_heading_uri: 'http://www.wikidata.org/entity/Q395',
          subject_heading_label: 'Mathematics',
          source_name: 'Wikidata',
          status: 'verified'
        )
      end

      it "displays external link for Wikidata subjects" do
        get subject_heading_path(Base64.urlsafe_encode64(wikidata_aboutness.subject_heading_uri))
        expect(response.body).to include(I18n.t('subject_headings.show.view_on_wikidata'))
      end
    end
  end

  describe "GET /subject_headings/autocomplete" do
    let!(:work) { Work.create!(title: 'Test Work') }
    let!(:expression) { Expression.create!(title: 'Test Expression') }
    let!(:manifestation) { Manifestation.create!(title: 'Test Manifestation') }
    let!(:embodiment) { Embodiment.create!(expression: expression, manifestation: manifestation) }
    let!(:reification) { Reification.create!(work: work, expression: expression) }

    let!(:aboutness) do
      Aboutness.create!(
        embodiment: embodiment,
        subject_heading_uri: 'https://id.loc.gov/authorities/subjects/sh85082139',
        subject_heading_label: 'Mathematics',
        source_name: 'LCSH',
        status: 'verified'
      )
    end

    it "returns JSON" do
      get autocomplete_subject_headings_path, params: { q: 'Math' }
      expect(response.content_type).to include('application/json')
    end

    it "returns matching results" do
      get autocomplete_subject_headings_path, params: { q: 'Math' }
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.length).to eq(1)
      expect(json.first['label']).to eq('Mathematics')
      expect(json.first['source']).to eq('LCSH')
      expect(json.first['uri']).to eq(aboutness.subject_heading_uri)
    end

    it "returns empty array for blank query" do
      get autocomplete_subject_headings_path, params: { q: '' }
      json = JSON.parse(response.body)
      expect(json).to eq([])
    end

    it "returns empty array for no matches" do
      get autocomplete_subject_headings_path, params: { q: 'NonExistent' }
      json = JSON.parse(response.body)
      expect(json).to eq([])
    end
  end
end

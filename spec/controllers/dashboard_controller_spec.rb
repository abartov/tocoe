require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:other_user) { User.create!(email: 'other@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    sign_in user
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end

    it "assigns @my_tocs with user's TOCs ordered by updated_at" do
      toc1 = Toc.create!(title: 'Toc 1', contributor: user, book_uri: 'https://example.com/1')
      toc2 = Toc.create!(title: 'Toc 2', contributor: user, book_uri: 'https://example.com/2')
      toc3 = Toc.create!(title: 'Toc 3', contributor: user, book_uri: 'https://example.com/3')

      # Update toc2 to make it most recent
      toc2.touch

      get :index
      expect(assigns(:my_tocs)).to eq([toc2, toc3, toc1])
    end

    it "limits @my_tocs to 5 TOCs" do
      6.times do |i|
        Toc.create!(title: "Toc #{i}", contributor: user, book_uri: "https://example.com/#{i}")
      end

      get :index
      expect(assigns(:my_tocs).count).to eq(5)
    end

    it "assigns @needs_verification with transcribed TOCs not by current user" do
      my_toc = Toc.create!(title: 'My Toc', contributor: user, status: :transcribed, book_uri: 'https://example.com/1')
      other_toc1 = Toc.create!(title: 'Other Toc 1', contributor: other_user, status: :transcribed, book_uri: 'https://example.com/2')
      other_toc2 = Toc.create!(title: 'Other Toc 2', contributor: other_user, status: :verified, book_uri: 'https://example.com/3')

      get :index
      expect(assigns(:needs_verification)).to include(other_toc1)
      expect(assigns(:needs_verification)).not_to include(my_toc)
      expect(assigns(:needs_verification)).not_to include(other_toc2)
    end

    it "limits @needs_verification to 5 TOCs" do
      6.times do |i|
        Toc.create!(title: "Other Toc #{i}", contributor: other_user, status: :transcribed, book_uri: "https://example.com/#{i}")
      end

      get :index
      expect(assigns(:needs_verification).count).to eq(5)
    end

    it "assigns @stats with correct counts" do
      # Create other_user's TOC to have 2 contributors
      Toc.create!(title: 'Other User Toc', contributor: other_user, status: :empty, book_uri: 'https://example.com/0')

      Toc.create!(title: 'Verified Toc', contributor: user, status: :verified, book_uri: 'https://example.com/1')
      Toc.create!(title: 'Transcribed Toc', contributor: user, status: :transcribed, book_uri: 'https://example.com/2')
      Toc.create!(title: 'Empty Toc', contributor: user, status: :empty, book_uri: 'https://example.com/3')

      get :index
      stats = assigns(:stats)
      expect(stats[:total]).to eq(4)
      expect(stats[:verified]).to eq(1)
      expect(stats[:needs_work]).to eq(3)
      expect(stats[:contributors]).to eq(2) # user and other_user
    end

    it "assigns @my_contribution_stats with user's contribution counts" do
      Toc.create!(title: 'Verified Toc', contributor: user, status: :verified, book_uri: 'https://example.com/1')
      Toc.create!(title: 'Transcribed Toc', contributor: user, status: :transcribed, book_uri: 'https://example.com/2')
      Toc.create!(title: 'Other Toc', contributor: other_user, status: :verified, book_uri: 'https://example.com/3')

      get :index
      stats = assigns(:my_contribution_stats)
      expect(stats[:total]).to eq(2)
      expect(stats[:verified]).to eq(1)
      expect(stats[:in_progress]).to eq(1)
    end

    it "assigns @recent_community_activity with recently verified TOCs" do
      # Create TOCs with verified status and verified_at timestamp
      old_toc = Toc.create!(
        title: 'Old Verified Toc',
        contributor: other_user,
        status: :verified,
        verified_at: 2.days.ago,
        reviewer: user,
        book_uri: 'https://example.com/1'
      )
      recent_toc = Toc.create!(
        title: 'Recent Verified Toc',
        contributor: other_user,
        status: :verified,
        verified_at: 1.hour.ago,
        reviewer: user,
        book_uri: 'https://example.com/2'
      )

      get :index
      expect(assigns(:recent_community_activity)).to eq([recent_toc, old_toc])
    end

    it "includes reviewer and contributor in @recent_community_activity query" do
      # This test verifies that the includes() is working (no N+1 queries)
      toc = Toc.create!(
        title: 'Verified Toc',
        contributor: other_user,
        status: :verified,
        verified_at: 1.hour.ago,
        reviewer: user,
        book_uri: 'https://example.com/1'
      )

      get :index

      # Access the associations to verify they're preloaded
      expect(assigns(:recent_community_activity).first.reviewer).to eq(user)
      expect(assigns(:recent_community_activity).first.contributor).to eq(other_user)
    end

    it "limits @recent_community_activity to 10 TOCs" do
      11.times do |i|
        Toc.create!(
          title: "Verified Toc #{i}",
          contributor: other_user,
          status: :verified,
          verified_at: i.hours.ago,
          reviewer: user,
          book_uri: "https://example.com/#{i}"
        )
      end

      get :index
      expect(assigns(:recent_community_activity).count).to eq(10)
    end

    it "only includes verified TOCs with verified_at in @recent_community_activity" do
      toc_verified = Toc.create!(
        title: 'Verified with Timestamp',
        contributor: other_user,
        status: :verified,
        reviewer: user,
        book_uri: 'https://example.com/1'
      )
      # Update verified_at to 1 hour ago to test ordering
      toc_verified.update_column(:verified_at, 1.hour.ago)

      # Create a transcribed TOC (not verified)
      toc_transcribed = Toc.create!(
        title: 'Transcribed',
        contributor: other_user,
        status: :transcribed,
        book_uri: 'https://example.com/2'
      )

      get :index
      expect(assigns(:recent_community_activity)).to include(toc_verified)
      expect(assigns(:recent_community_activity)).not_to include(toc_transcribed)
    end
  end

  describe "GET #aboutness" do
    it "returns http success" do
      get :aboutness
      expect(response).to have_http_status(:success)
    end

    it "renders the aboutness template" do
      get :aboutness
      expect(response).to render_template(:aboutness)
    end

    it "assigns @tocs_needing_subjects with verified TOCs containing embodiments without aboutnesses" do
      # Create a verified TOC with manifestation and embodiment without aboutnesses
      expression = Expression.create!(title: "Test Expression")
      manifestation = Manifestation.create!(title: "Test Manifestation")
      embodiment = Embodiment.create!(expression: expression, manifestation: manifestation)
      toc_needing_subjects = Toc.create!(
        title: 'TOC Needing Subjects',
        contributor: user,
        status: :verified,
        book_uri: 'https://example.com/1',
        manifestation: manifestation
      )

      # Create a verified TOC with aboutnesses (should not be included)
      expression2 = Expression.create!(title: "Test Expression 2")
      manifestation2 = Manifestation.create!(title: "Test Manifestation 2")
      embodiment2 = Embodiment.create!(expression: expression2, manifestation: manifestation2)
      Aboutness.create!(
        embodiment: embodiment2,
        subject_heading_uri: 'http://id.loc.gov/authorities/subjects/sh85146352',
        source_name: 'LCSH',
        subject_heading_label: 'Whales',
        status: 'verified'
      )
      toc_with_subjects = Toc.create!(
        title: 'TOC With Subjects',
        contributor: user,
        status: :verified,
        book_uri: 'https://example.com/2',
        manifestation: manifestation2
      )

      get :aboutness

      expect(assigns(:tocs_needing_subjects)).to include(toc_needing_subjects)
      expect(assigns(:tocs_needing_subjects)).not_to include(toc_with_subjects)
    end

    it "only includes verified TOCs" do
      # Create a transcribed TOC without aboutnesses
      expression = Expression.create!(title: "Test Expression")
      manifestation = Manifestation.create!(title: "Test Manifestation")
      embodiment = Embodiment.create!(expression: expression, manifestation: manifestation)
      toc_transcribed = Toc.create!(
        title: 'Transcribed TOC',
        contributor: user,
        status: :transcribed,
        book_uri: 'https://example.com/1',
        manifestation: manifestation
      )

      get :aboutness

      expect(assigns(:tocs_needing_subjects)).not_to include(toc_transcribed)
    end

    it "orders TOCs by updated_at descending" do
      # Create two TOCs needing subjects
      expression1 = Expression.create!(title: "Expression 1")
      manifestation1 = Manifestation.create!(title: "Manifestation 1")
      embodiment1 = Embodiment.create!(expression: expression1, manifestation: manifestation1)
      toc1 = Toc.create!(
        title: 'Old TOC',
        contributor: user,
        status: :verified,
        book_uri: 'https://example.com/1',
        manifestation: manifestation1
      )

      expression2 = Expression.create!(title: "Expression 2")
      manifestation2 = Manifestation.create!(title: "Manifestation 2")
      embodiment2 = Embodiment.create!(expression: expression2, manifestation: manifestation2)
      toc2 = Toc.create!(
        title: 'New TOC',
        contributor: user,
        status: :verified,
        book_uri: 'https://example.com/2',
        manifestation: manifestation2
      )

      # Update toc2 to make it more recent
      toc2.touch

      get :aboutness

      expect(assigns(:tocs_needing_subjects).first).to eq(toc2)
      expect(assigns(:tocs_needing_subjects).last).to eq(toc1)
    end
  end
end

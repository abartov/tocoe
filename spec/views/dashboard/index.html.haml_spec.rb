require 'rails_helper'

RSpec.describe "dashboard/index", type: :view do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:other_user) { User.create!(email: 'other@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context "with stats data" do
    before do
      assign(:stats, {
        total: 10,
        verified: 5,
        needs_work: 5,
        contributors: 3
      })
      assign(:my_tocs, [])
      assign(:needs_verification, [])
      assign(:my_contribution_stats, { total: 0, verified: 0, in_progress: 0 })
      assign(:recent_community_activity, [])
    end

    it "displays the statistics cards" do
      render
      expect(rendered).to have_selector('.stat-card', count: 4)
      expect(rendered).to have_content('10') # total
      expect(rendered).to have_content('5') # verified
      expect(rendered).to have_content('3') # contributors
    end

    it "displays the stat labels" do
      render
      expect(rendered).to have_content(I18n.t('dashboard.stats.total_tocs'))
      expect(rendered).to have_content(I18n.t('dashboard.stats.verified'))
      expect(rendered).to have_content(I18n.t('dashboard.stats.needs_work'))
      expect(rendered).to have_content(I18n.t('dashboard.stats.contributors'))
    end
  end

  context "with user's recent TOCs" do
    before do
      @toc1 = Toc.create!(title: 'My Toc 1', contributor: user, status: :empty, book_uri: 'https://example.com/1')
      @toc2 = Toc.create!(title: 'My Toc 2', contributor: user, status: :verified, book_uri: 'https://example.com/2')

      assign(:my_tocs, [@toc1, @toc2])
      assign(:stats, { total: 2, verified: 1, needs_work: 1, contributors: 1 })
      assign(:needs_verification, [])
      assign(:my_contribution_stats, { total: 2, verified: 1, in_progress: 1 })
      assign(:recent_community_activity, [])
    end

    it "displays the TOC cards" do
      render
      expect(rendered).to have_selector('.toc-card', count: 2)
      expect(rendered).to have_content('My Toc 1')
      expect(rendered).to have_content('My Toc 2')
    end

    it "displays status badges" do
      render
      expect(rendered).to have_selector('.status-badge.status-empty')
      expect(rendered).to have_selector('.status-badge.status-verified')
    end

    it "displays 'View All My TOCs' link" do
      render
      expect(rendered).to have_link(I18n.t('dashboard.view_all_my_tocs'), href: tocs_path)
    end
  end

  context "without user's TOCs" do
    before do
      assign(:my_tocs, [])
      assign(:stats, { total: 0, verified: 0, needs_work: 0, contributors: 1 })
      assign(:needs_verification, [])
      assign(:my_contribution_stats, { total: 0, verified: 0, in_progress: 0 })
      assign(:recent_community_activity, [])
    end

    it "displays empty state message" do
      render
      expect(rendered).to have_selector('.empty-state')
      expect(rendered).to have_content('You haven\'t created any TOCs yet')
    end

    it "displays 'Start Contributing' link" do
      render
      expect(rendered).to have_link(I18n.t('dashboard.start_contributing'), href: publications_search_path)
    end

    it "does not display 'View All My TOCs' link" do
      render
      expect(rendered).not_to have_link(I18n.t('dashboard.view_all_my_tocs'))
    end
  end

  context "with contribution stats" do
    before do
      @toc = Toc.create!(title: 'My Toc', contributor: user, status: :verified, book_uri: 'https://example.com/1')

      assign(:my_tocs, [@toc])
      assign(:stats, { total: 1, verified: 1, needs_work: 0, contributors: 1 })
      assign(:needs_verification, [])
      assign(:my_contribution_stats, { total: 5, verified: 3, in_progress: 2 })
      assign(:recent_community_activity, [])
    end

    it "displays My Contribution Stats section" do
      render
      expect(rendered).to have_content(I18n.t('dashboard.my_contribution_stats'))
      expect(rendered).to have_selector('.my-stats-grid')
    end

    it "displays personal stats" do
      render
      expect(rendered).to have_selector('.my-stat-card', count: 3)
      expect(rendered).to have_content('5') # total
      expect(rendered).to have_content('3') # verified
      expect(rendered).to have_content('2') # in_progress
    end
  end

  context "with TOCs needing verification" do
    before do
      @other_toc = Toc.create!(title: 'Other Toc', contributor: other_user, status: :transcribed, book_uri: 'https://example.com/1')

      assign(:my_tocs, [])
      assign(:stats, { total: 1, verified: 0, needs_work: 1, contributors: 2 })
      assign(:needs_verification, [@other_toc])
      assign(:my_contribution_stats, { total: 0, verified: 0, in_progress: 0 })
      assign(:recent_community_activity, [])
    end

    it "displays Needs Attention section" do
      render
      expect(rendered).to have_content(I18n.t('dashboard.needs_attention'))
    end

    it "displays mini TOC cards" do
      render
      expect(rendered).to have_selector('.mini-toc-card')
      expect(rendered).to have_content('Other Toc')
      expect(rendered).to have_content(I18n.t('dashboard.ready_to_verify'))
    end
  end

  context "without TOCs needing verification" do
    before do
      assign(:my_tocs, [])
      assign(:stats, { total: 0, verified: 0, needs_work: 0, contributors: 1 })
      assign(:needs_verification, [])
      assign(:my_contribution_stats, { total: 0, verified: 0, in_progress: 0 })
      assign(:recent_community_activity, [])
    end

    it "displays no verification needed message" do
      render
      expect(rendered).to have_content(I18n.t('dashboard.no_verification_needed'))
    end
  end

  context "with recent community activity" do
    before do
      @verified_toc = Toc.create!(
        title: 'Community Toc',
        contributor: other_user,
        status: :verified,
        verified_at: 1.hour.ago,
        reviewer: user,
        book_uri: 'https://example.com/1'
      )

      assign(:my_tocs, [])
      assign(:stats, { total: 1, verified: 1, needs_work: 0, contributors: 2 })
      assign(:needs_verification, [])
      assign(:my_contribution_stats, { total: 0, verified: 0, in_progress: 0 })
      assign(:recent_community_activity, [@verified_toc])
    end

    it "displays Recent Community Activity section" do
      render
      expect(rendered).to have_content(I18n.t('dashboard.recent_community_activity'))
    end

    it "displays activity feed" do
      render
      expect(rendered).to have_selector('.activity-feed')
      expect(rendered).to have_selector('.activity-item')
      expect(rendered).to have_content('Community Toc')
    end

    it "displays reviewer information" do
      render
      expect(rendered).to match(/Verified by.*#{user.email}/)
    end
  end

  context "with quick actions" do
    before do
      assign(:my_tocs, [])
      assign(:stats, { total: 0, verified: 0, needs_work: 0, contributors: 1 })
      assign(:needs_verification, [])
      assign(:my_contribution_stats, { total: 0, verified: 0, in_progress: 0 })
      assign(:recent_community_activity, [])
    end

    it "displays quick actions section" do
      render
      expect(rendered).to have_content(I18n.t('dashboard.quick_actions'))
    end

    it "displays action buttons" do
      render
      expect(rendered).to have_selector('.action-button', count: 2)
      expect(rendered).to have_link(I18n.t('dashboard.actions.search_books'), href: publications_search_path)
      expect(rendered).to have_link(I18n.t('dashboard.actions.verify_tocs'), href: tocs_path)
    end
  end
end

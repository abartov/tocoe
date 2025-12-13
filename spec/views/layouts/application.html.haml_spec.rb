require 'rails_helper'

RSpec.describe "layouts/application.html.haml", type: :view do
  before do
    allow(view).to receive(:user_signed_in?).and_return(false)
    allow(Devise).to receive(:omniauth_configs).and_return({})
    allow(view).to receive(:render_breadcrumbs).and_return('')
    allow(view).to receive(:nav_link_class).and_return('')
    allow(I18n).to receive(:available_locales).and_return([:en])
  end

  it "displays the ToCoE logo that links to the home page" do
    render

    expect(rendered).to have_selector('a.tocoe-logo-link[href="/"]')
    expect(rendered).to have_selector('img.tocoe-logo[alt="ToCoE"]')
    expect(rendered).to have_selector('img.tocoe-logo[src*="tocoe-logo"]')
  end

  context "when user is signed in" do
    let(:user) { double('User', email: 'test@example.com') }

    before do
      allow(view).to receive(:user_signed_in?).and_return(true)
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:destroy_user_session_path).and_return('/users/sign_out')
      allow(view).to receive(:tocs_path).and_return('/tocs')
      allow(view).to receive(:publications_search_path).and_return('/publications/search')
      allow(view).to receive(:dashboard_aboutness_path).and_return('/dashboard/aboutness')
      allow(view).to receive(:help_path).and_return('/help')
      allow(view).to receive(:search_tocs_path).and_return('/tocs/search')
      allow(view).to receive(:locale_path).and_return('/locale/en')
    end

    it "displays the logo alongside user info" do
      render

      expect(rendered).to have_selector('a.tocoe-logo-link[href="/"]')
      expect(rendered).to have_content('test@example.com')
      expect(rendered).to have_selector('.user-menu-wrapper')
    end

    it "displays the Subject Headings navigation link" do
      render

      expect(rendered).to have_link('🏷️ Subject Headings', href: '/dashboard/aboutness')
    end

    it "displays all navigation links" do
      render

      expect(rendered).to have_link('🏠 Dashboard', href: '/')
      expect(rendered).to have_link('🔍 Search', href: '/publications/search')
      expect(rendered).to have_link('📚 TOCs', href: '/tocs')
      expect(rendered).to have_link('🏷️ Subject Headings', href: '/dashboard/aboutness')
      expect(rendered).to have_selector('a[href="/help"]')
    end

    it "displays the language selector" do
      render

      expect(rendered).to have_selector('.language-selector')
      expect(rendered).to have_selector('button.language-button')
      expect(rendered).to have_selector('.language-dropdown')
    end
  end
end

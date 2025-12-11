require 'rails_helper'

RSpec.describe "layouts/application.html.erb", type: :view do
  before do
    allow(view).to receive(:user_signed_in?).and_return(false)
    allow(Devise).to receive(:omniauth_configs).and_return({})
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
    end

    it "displays the logo alongside user info" do
      render

      expect(rendered).to have_selector('a.tocoe-logo-link[href="/"]')
      expect(rendered).to have_content('test@example.com')
      expect(rendered).to have_selector('.user-menu-wrapper')
    end
  end
end

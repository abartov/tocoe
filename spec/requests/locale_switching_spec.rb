require 'rails_helper'

RSpec.describe "Locale switching", type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    sign_in user
  end

  describe "GET /locale/:locale" do
    context "with valid locale" do
      it "sets the session locale" do
        get locale_path(locale: 'en')
        expect(session[:locale]).to eq('en')
      end

      it "redirects back to the referring page" do
        get locale_path(locale: 'en'), headers: { 'HTTP_REFERER' => tocs_path }
        expect(response).to redirect_to(tocs_path)
      end

      it "redirects to root if no referer" do
        get locale_path(locale: 'en')
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid locale" do
      it "does not set the session locale" do
        get locale_path(locale: 'invalid')
        expect(session[:locale]).to be_nil
      end

      it "still redirects back" do
        get locale_path(locale: 'invalid'), headers: { 'HTTP_REFERER' => tocs_path }
        expect(response).to redirect_to(tocs_path)
      end
    end
  end

  describe "locale persistence" do
    it "persists the locale across requests" do
      # Set locale
      get locale_path(locale: 'en')

      # Make another request
      get root_path
      expect(I18n.locale).to eq(:en)
    end

    it "uses default locale if no session locale is set" do
      get root_path
      expect(I18n.locale).to eq(I18n.default_locale)
    end
  end
end

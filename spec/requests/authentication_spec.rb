require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

  describe "protected routes" do
    it "redirects to sign in when accessing tocs without authentication" do
      get tocs_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to sign in when accessing publications without authentication" do
      get publications_search_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows access to tocs when authenticated" do
      sign_in user
      get tocs_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "public routes" do
    it "allows access to homepage without authentication" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "Devise routes" do
    it "allows access to OAuth authorize endpoint without authentication" do
      # This should not redirect to sign in - it should process the OAuth flow
      post user_google_oauth2_omniauth_authorize_path
      # Expect it to redirect to Google OAuth (not to sign in page)
      expect(response).to have_http_status(:redirect)
      expect(response.location).not_to include('users/sign_in')
    end
  end
end

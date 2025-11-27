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
end

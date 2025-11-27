require 'rails_helper'

RSpec.describe "Homes", type: :request do
  describe "GET /" do
    it "returns http success without authentication" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "displays the project description" do
      get root_path
      expect(response.body).to include('Table of Contents of Everything')
      expect(response.body).to include('CC0')
    end

    it "shows sign-in link when not logged in" do
      get root_path
      expect(response.body).to include('Sign in with Google')
    end

    it "shows View Existing TOCs button when logged in" do
      user = User.create!(email: 'test@example.com', password: 'password123')
      sign_in user

      get root_path
      expect(response.body).to include('View Existing TOCs')
      expect(response.body).to include(tocs_path)
    end
  end
end

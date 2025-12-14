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

    it "redirects to dashboard when logged in" do
      user = User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123')
      sign_in user

      get root_path
      expect(response).to redirect_to(dashboard_index_path)
    end

    it "displays visual examples section" do
      get root_path
      expect(response.body).to include('See ToCoE in Action')
      expect(response.body).to include('Real examples of tables of contents')
    end

    it "displays example images" do
      get root_path
      expect(response.body).to include('Detailed TOC View with Original Scans')
      expect(response.body).to include('Browse All Tables of Contents')
    end
  end
end

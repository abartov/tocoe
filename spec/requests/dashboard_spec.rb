require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  describe "GET /index" do
    it "returns http success" do
      sign_in user
      get "/dashboard/index"
      expect(response).to have_http_status(:success)
    end
  end

end

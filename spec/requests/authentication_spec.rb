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

  describe "OAuth authentication" do
    describe "Google OAuth2 callback" do
      context "with valid OAuth credentials" do
        before do
          setup_oauth_mock(
            uid: '12345',
            email: 'oauth@example.com',
            name: 'OAuth User'
          )
        end

        it "creates a new user and signs them in" do
          expect {
            get user_google_oauth2_omniauth_callback_path
          }.to change(User, :count).by(1)

          user = User.last
          expect(user.email).to eq('oauth@example.com')
          expect(user.name).to eq('OAuth User')
          expect(user.provider).to eq('google_oauth2')
          expect(user.uid).to eq('12345')

          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to include('Google')
        end

        it "signs in an existing user with matching email" do
          existing_user = User.create!(
            email: 'oauth@example.com',
            password: 'password123'
          )

          expect {
            get user_google_oauth2_omniauth_callback_path
          }.not_to change(User, :count)

          existing_user.reload
          expect(existing_user.provider).to eq('google_oauth2')
          expect(existing_user.uid).to eq('12345')
          expect(existing_user.name).to eq('OAuth User')

          expect(response).to redirect_to(root_path)
        end

        it "signs in an existing OAuth user" do
          existing_user = User.create!(
            email: 'oauth@example.com',
            password: 'password123',
            provider: 'google_oauth2',
            uid: '12345',
            name: 'OAuth User'
          )

          expect {
            get user_google_oauth2_omniauth_callback_path
          }.not_to change(User, :count)

          expect(response).to redirect_to(root_path)
        end
      end

      context "with invalid OAuth credentials" do
        before do
          setup_oauth_failure
        end

        it "handles authentication failure" do
          # When OAuth fails, OmniAuth redirects to the failure callback
          # which is handled by the failure action in the controller
          get '/users/auth/google_oauth2/callback'
          expect(response).to redirect_to(root_path)
        end
      end
    end

  end
end

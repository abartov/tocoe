# frozen_string_literal: true

# This file demonstrates how to use the OmniAuth mocks in your tests.
# It's for documentation purposes only and can be safely deleted.
#
# The OmniAuth mocks are automatically configured in spec/support/omniauth_helpers.rb
# and allow all tests to run without valid Google OAuth2 credentials.

require 'rails_helper'

RSpec.describe 'OAuth Mock Usage Examples', type: :request do
  # Example 1: Basic OAuth mock (automatically set up for all tests)
  # The default mock is already configured, so you can just test OAuth flows
  describe 'Default OAuth mock' do
    it 'is already configured with test credentials' do
      # Just call the OAuth callback - the mock is already set up
      get user_google_oauth2_omniauth_callback_path

      expect(response).to redirect_to(root_path)
      expect(User.last.email).to eq('test@example.com')
    end
  end

  # Example 2: Custom OAuth credentials
  describe 'Custom OAuth mock' do
    before do
      # Override the default mock with custom data
      setup_oauth_mock(
        uid: '999',
        email: 'custom@example.com',
        name: 'Custom User'
      )
    end

    it 'uses the custom credentials' do
      get user_google_oauth2_omniauth_callback_path

      user = User.last
      expect(user.email).to eq('custom@example.com')
      expect(user.name).to eq('Custom User')
      expect(user.uid).to eq('999')
    end
  end

  # Example 3: Testing OAuth failures
  describe 'OAuth failure handling' do
    before do
      # Simulate an OAuth failure
      setup_oauth_failure
    end

    it 'handles authentication failures gracefully' do
      get user_google_oauth2_omniauth_callback_path

      expect(response).to redirect_to(root_path)
      # The user should not be signed in
      expect(controller.current_user).to be_nil
    end
  end

  # Example 4: Manual auth hash creation
  describe 'Manual auth hash' do
    it 'can create a custom auth hash directly' do
      auth_hash = mock_google_oauth2_auth(
        uid: '12345',
        email: 'manual@example.com',
        name: 'Manual User'
      )

      # You can now use this auth hash in your tests
      expect(auth_hash.provider).to eq('google_oauth2')
      expect(auth_hash.uid).to eq('12345')
      expect(auth_hash.info.email).to eq('manual@example.com')
      expect(auth_hash.info.name).to eq('Manual User')

      # You could pass this to User.from_omniauth directly:
      user = User.from_omniauth(auth_hash)
      expect(user).to be_persisted
      expect(user.email).to eq('manual@example.com')
    end
  end
end

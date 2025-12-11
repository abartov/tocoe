# OmniAuth test mode configuration and helpers
# This allows tests to run without valid OAuth credentials

module OmniauthHelpers
  # Generate a mock OmniAuth auth hash for Google OAuth2
  # This simulates the data structure returned by Google OAuth
  #
  # Usage:
  #   let(:auth_hash) { mock_google_oauth2_auth }
  #   before { OmniAuth.config.mock_auth[:google_oauth2] = auth_hash }
  #
  # Or with custom data:
  #   mock_google_oauth2_auth(
  #     uid: '12345',
  #     email: 'custom@example.com',
  #     name: 'Custom Name'
  #   )
  def mock_google_oauth2_auth(uid: '123456789', email: 'test@example.com', name: 'Test User')
    OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: uid,
      info: {
        name: name,
        email: email,
        first_name: name.split.first,
        last_name: name.split.last,
        image: 'https://example.com/avatar.jpg'
      },
      credentials: {
        token: 'mock_token',
        refresh_token: 'mock_refresh_token',
        expires_at: 1.hour.from_now.to_i,
        expires: true
      },
      extra: {
        raw_info: {
          sub: uid,
          email: email,
          email_verified: true,
          name: name
        }
      }
    )
  end

  # Set up a successful OAuth mock for the current test
  # This is a convenience method that sets the mock and cleans up after
  #
  # Usage:
  #   before { setup_oauth_mock }
  #
  # Or with custom data:
  #   before { setup_oauth_mock(email: 'custom@example.com') }
  def setup_oauth_mock(**options)
    OmniAuth.config.mock_auth[:google_oauth2] = mock_google_oauth2_auth(**options)
  end

  # Set up a failed OAuth mock for testing error handling
  #
  # Usage:
  #   before { setup_oauth_failure }
  def setup_oauth_failure
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
  end
end

RSpec.configure do |config|
  # Enable OmniAuth test mode for all specs
  # This prevents OmniAuth from making real HTTP requests during tests
  config.before(:suite) do
    OmniAuth.config.test_mode = true
  end

  # Include OmniAuth helpers in all request and feature specs
  config.include OmniauthHelpers, type: :request
  config.include OmniauthHelpers, type: :feature
  config.include OmniauthHelpers, type: :controller

  # Set up a default successful mock for all tests
  # Individual tests can override this if needed
  config.before(:each) do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    setup_oauth_mock if respond_to?(:setup_oauth_mock)
  end

  # Clean up OmniAuth mocks after each test
  config.after(:each) do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  # Disable OmniAuth test mode after the suite
  # This ensures test mode doesn't leak into other processes
  config.after(:suite) do
    OmniAuth.config.test_mode = false
  end
end

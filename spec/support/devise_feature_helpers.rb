# Helpers for mocking authentication in feature specs (Capybara tests)
module DeviseFeatureHelpers
  # Sign in a user for feature/system tests using Warden test helpers
  # This bypasses the authentication UI and directly logs in the user
  #
  # Usage:
  #   let(:user) { create(:user) }
  #   before { sign_in_as(user) }
  #
  # Or inline in a scenario:
  #   scenario 'doing something as logged in user' do
  #     user = create(:user)
  #     sign_in_as(user)
  #     visit some_path
  #   end
  def sign_in_as(user)
    login_as(user, scope: :user)
  end
end

RSpec.configure do |config|
  # Include Devise test helpers for feature specs
  # This provides the login_as and logout methods from Warden::Test::Helpers
  config.include Warden::Test::Helpers, type: :feature
  config.include DeviseFeatureHelpers, type: :feature

  # Clean up Warden test mode after each feature spec
  config.after(:each, type: :feature) do
    Warden.test_reset!
  end
end

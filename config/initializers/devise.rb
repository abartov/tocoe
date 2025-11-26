Devise.setup do |config|
  config.mailer_sender = 'noreply@tocoe.local'
  config.skip_session_storage = %i[http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.pepper = ENV['DEVISE_PEPPER'] if ENV['DEVISE_PEPPER'].present?
  secret_key_base = Rails.application.credentials.secret_key_base.presence || Rails.application.secrets.secret_key_base.presence
  config.secret_key = secret_key_base if secret_key_base

  google_client_id = Rails.configuration.constants['google_oauth2_client_id']
  google_client_secret = Rails.configuration.constants['google_oauth2_client_secret']

  if google_client_id.present? && google_client_secret.present?
    config.omniauth :google_oauth2,
                    google_client_id,
                    google_client_secret,
                    scope: 'email,profile',
                    prompt: 'select_account'
  end
end

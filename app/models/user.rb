class User < ApplicationRecord
  extend Devise::Models
  devise :database_authenticatable, :recoverable, :rememberable, :validatable,
         :registerable, :omniauthable, omniauth_providers: %i[google_oauth2]

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  def self.from_omniauth(auth)
    return unless auth&.provider && auth&.uid

    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)

    if user.new_record? && auth.info.email.present?
      existing = find_by(email: auth.info.email)
      if existing
        user = existing
        user.provider ||= auth.provider
        user.uid ||= auth.uid
      end
    end

    user.name = auth.info.name if user.name.blank? && auth.info.name.present?
    user.email = auth.info.email if user.email.blank? && auth.info.email.present?
    user.password = Devise.friendly_token[0, 20] if user.encrypted_password.blank?

    user.save
    user
  end
end

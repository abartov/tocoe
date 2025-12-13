require 'rest-client'
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :set_locale

#  OL_CLIENT = Openlibrary::Client.new
#  def ol_client
#    return OL_CLIENT
#  end
  def rest_get(url)
    JSON.parse(RestClient.get(url))
  end

  def set_locale
    I18n.locale = session[:locale] || I18n.default_locale
  end

  def switch_locale
    if I18n.available_locales.include?(params[:locale]&.to_sym)
      session[:locale] = params[:locale]
      I18n.locale = params[:locale]
    end
    redirect_back(fallback_location: root_path)
  end
end

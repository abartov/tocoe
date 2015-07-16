require 'rest-client'
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
#  OL_CLIENT = Openlibrary::Client.new
#  def ol_client
#    return OL_CLIENT
#  end
  def rest_get(url)
    JSON.parse(RestClient.get(url))
  end
end

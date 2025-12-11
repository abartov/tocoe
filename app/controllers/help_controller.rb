class HelpController < ApplicationController
  # Allow unauthenticated access to help pages
  skip_before_action :authenticate_user!, only: [:index]

  def index
    # Help page - renders comprehensive documentation
  end
end

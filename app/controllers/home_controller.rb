class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    # Redirect signed-in users to dashboard
    if user_signed_in?
      redirect_to dashboard_index_path
    end
  end
end

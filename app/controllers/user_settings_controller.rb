class UserSettingsController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      flash[:notice] = I18n.t('user_settings.flash.updated_successfully')
      redirect_to edit_user_settings_path
    else
      flash.now[:error] = I18n.t('user_settings.flash.update_failed')
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:help_enabled, :name, :email)
  end
end

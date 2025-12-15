require 'rails_helper'

RSpec.describe UserSettingsController, type: :controller do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    sign_in user
  end

  describe 'GET #edit' do
    it 'renders the edit template' do
      get :edit
      expect(response).to render_template(:edit)
    end

    it 'assigns the current user' do
      get :edit
      expect(assigns(:user)).to eq(user)
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      it 'updates the user help preference' do
        patch :update, params: { user: { help_enabled: false } }
        expect(user.reload.help_enabled).to be false
      end

      it 'redirects to edit page with success message' do
        patch :update, params: { user: { help_enabled: false } }
        expect(response).to redirect_to(edit_user_settings_path)
        expect(flash[:notice]).to eq(I18n.t('user_settings.flash.updated_successfully'))
      end
    end

    context 'with invalid parameters' do
      it 'renders edit template with error' do
        allow_any_instance_of(User).to receive(:update).and_return(false)
        patch :update, params: { user: { help_enabled: false } }
        expect(response).to render_template(:edit)
        expect(flash.now[:error]).to eq(I18n.t('user_settings.flash.update_failed'))
      end
    end
  end
end

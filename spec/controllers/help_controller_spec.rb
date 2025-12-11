require 'rails_helper'

RSpec.describe HelpController, type: :controller do
  describe 'GET #index' do
    context 'when user is not authenticated' do
      it 'allows access to help page' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context 'when user is authenticated' do
      let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

      before do
        sign_in user
      end

      it 'allows access to help page' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end
  end
end

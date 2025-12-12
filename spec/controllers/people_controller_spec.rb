require 'rails_helper'

RSpec.describe PeopleController, type: :controller do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let(:person) { Person.create!(name: 'Test Author', dates: '1564-1616') }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'assigns all people ordered by name' do
      person1 = Person.create!(name: 'Zoe Author')
      person2 = Person.create!(name: 'Alice Author')
      person3 = Person.create!(name: 'Bob Author')

      get :index

      expect(assigns(:people)).to eq([person2, person3, person1])
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end

    it 'requires authentication' do
      sign_out user
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET #show' do
    it 'assigns the requested person' do
      get :show, params: { id: person.id }
      expect(assigns(:person)).to eq(person)
    end

    it 'renders the show template' do
      get :show, params: { id: person.id }
      expect(response).to render_template(:show)
    end

    it 'requires authentication' do
      sign_out user
      get :show, params: { id: person.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET #new' do
    it 'assigns a new person' do
      get :new
      expect(assigns(:person)).to be_a_new(Person)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end

    it 'requires authentication' do
      sign_out user
      get :new
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new person' do
        expect {
          post :create, params: { person: { name: 'New Author', dates: '1800-1900' } }
        }.to change(Person, :count).by(1)
      end

      it 'redirects to the person show page' do
        post :create, params: { person: { name: 'New Author' } }
        expect(response).to redirect_to(Person.last)
      end

      it 'sets a success flash message' do
        post :create, params: { person: { name: 'New Author' } }
        expect(flash[:notice]).to eq(I18n.t('people.flash.created_successfully'))
      end

      it 'saves all permitted attributes' do
        post :create, params: {
          person: {
            name: 'New Author',
            dates: '1800-1900',
            title: 'Dr.',
            affiliation: 'University',
            country: 'USA',
            comment: 'Test comment',
            viaf_id: 12345678,
            wikidata_q: 87654321,
            openlibrary_id: '/authors/OL123A',
            loc_id: 'n79021164',
            gutenberg_id: 4527
          }
        }

        created_person = Person.last
        expect(created_person.name).to eq('New Author')
        expect(created_person.dates).to eq('1800-1900')
        expect(created_person.title).to eq('Dr.')
        expect(created_person.affiliation).to eq('University')
        expect(created_person.country).to eq('USA')
        expect(created_person.comment).to eq('Test comment')
        expect(created_person.viaf_id).to eq(12345678)
        expect(created_person.wikidata_q).to eq(87654321)
        expect(created_person.openlibrary_id).to eq('/authors/OL123A')
        expect(created_person.loc_id).to eq('n79021164')
        expect(created_person.gutenberg_id).to eq(4527)
      end
    end

    context 'with invalid attributes' do
      it 'does not create a new person' do
        expect {
          post :create, params: { person: { name: '' } }
        }.not_to change(Person, :count)
      end

      it 'renders the new template' do
        post :create, params: { person: { name: '' } }
        expect(response).to render_template(:new)
      end

      it 'returns unprocessable entity status' do
        post :create, params: { person: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it 'requires authentication' do
      sign_out user
      post :create, params: { person: { name: 'New Author' } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested person' do
      get :edit, params: { id: person.id }
      expect(assigns(:person)).to eq(person)
    end

    it 'renders the edit template' do
      get :edit, params: { id: person.id }
      expect(response).to render_template(:edit)
    end

    it 'requires authentication' do
      sign_out user
      get :edit, params: { id: person.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'PATCH #update' do
    context 'with valid attributes' do
      it 'updates the person' do
        patch :update, params: { id: person.id, person: { name: 'Updated Author' } }
        person.reload
        expect(person.name).to eq('Updated Author')
      end

      it 'redirects to the person show page' do
        patch :update, params: { id: person.id, person: { name: 'Updated Author' } }
        expect(response).to redirect_to(person)
      end

      it 'sets a success flash message' do
        patch :update, params: { id: person.id, person: { name: 'Updated Author' } }
        expect(flash[:notice]).to eq(I18n.t('people.flash.updated_successfully'))
      end

      it 'updates all permitted attributes' do
        patch :update, params: {
          id: person.id,
          person: {
            name: 'Updated Author',
            dates: '1900-2000',
            title: 'Prof.',
            affiliation: 'College',
            country: 'UK',
            comment: 'Updated comment',
            viaf_id: 11111111,
            wikidata_q: 22222222,
            openlibrary_id: '/authors/OL999Z',
            loc_id: 'n99999999',
            gutenberg_id: 9999
          }
        }

        person.reload
        expect(person.name).to eq('Updated Author')
        expect(person.dates).to eq('1900-2000')
        expect(person.title).to eq('Prof.')
        expect(person.affiliation).to eq('College')
        expect(person.country).to eq('UK')
        expect(person.comment).to eq('Updated comment')
        expect(person.viaf_id).to eq(11111111)
        expect(person.wikidata_q).to eq(22222222)
        expect(person.openlibrary_id).to eq('/authors/OL999Z')
        expect(person.loc_id).to eq('n99999999')
        expect(person.gutenberg_id).to eq(9999)
      end
    end

    context 'with invalid attributes' do
      it 'does not update the person' do
        patch :update, params: { id: person.id, person: { name: '' } }
        person.reload
        expect(person.name).to eq('Test Author')
      end

      it 'renders the edit template' do
        patch :update, params: { id: person.id, person: { name: '' } }
        expect(response).to render_template(:edit)
      end

      it 'returns unprocessable entity status' do
        patch :update, params: { id: person.id, person: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it 'requires authentication' do
      sign_out user
      patch :update, params: { id: person.id, person: { name: 'Updated Author' } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end

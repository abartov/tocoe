Rails.application.routes.draw do
  get "dashboard/index"
  get "dashboard/aboutness", to: "dashboard#aboutness"
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  get 'manifestations/show'

  get 'manifestations/approve'

  resources :tocs do
    collection do
      post :create_multiple
      get :search
    end
    member do
      get :browse_scans
      post :mark_pages
      post :mark_transcribed
      post :verify
      post :auto_match_subjects
    end
  end
  get 'publications/search'

  get 'publications/details' => "publications#details"

  get 'publications/browse'

  get 'publications/savetoc'

  post 'tocs/do_ocr' => "tocs#do_ocr"

  # Aboutnesses - nested under embodiments
  resources :embodiments, only: [] do
    resources :aboutnesses, only: [:index, :new, :create] do
      collection do
        post :search
      end
    end
  end

  # Aboutnesses - destroy and verify don't need embodiment nesting
  resources :aboutnesses, only: [:destroy] do
    member do
      patch :verify
    end
  end

  # Help page
  get 'help', to: 'help#index'

  # People (authors/creators) management
  resources :people, only: [:index, :show, :new, :create, :edit, :update]

  root 'home#index'
end

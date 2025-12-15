Rails.application.routes.draw do
  # Subject Headings browser - for exploring aboutnesses
  resources :subject_headings, only: [:index, :show] do
    collection do
      get :autocomplete
    end
  end

  get "dashboard/index"
  get "dashboard/aboutness", to: "dashboard#aboutness"
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  get 'manifestations/show'

  get 'manifestations/approve'

  resources :tocs do
    collection do
      post :create_multiple
      get :search
      get :gutenberg_proxy
    end
    member do
      get :browse_scans
      get :download
      post :mark_pages
      post :mark_transcribed
      post :verify
      post :auto_match_subjects
      get :review_authors
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

  # Public (unauthenticated) verified TOCs
  get 'browse', to: 'public_tocs#index', as: :browse_tocs
  get 'browse/:id', to: 'public_tocs#show', as: :browse_toc
  get 'browse/:id/download', to: 'public_tocs#download', as: :download_browse

  # Locale switching
  get 'locale/:locale', to: 'application#switch_locale', as: :locale

  # People (authors/creators) management
  resources :people, only: [:index, :show, :new, :create, :edit, :update] do
    collection do
      post :search_viaf
      post :search_wikidata
      post :search_loc
      post :search_all
      get :fetch_details
      post :match
      post :accept_parent_match
      post :undo_match
    end
  end

  root 'home#index'
end

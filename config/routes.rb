Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  get 'manifestations/show'

  get 'manifestations/approve'

  resources :tocs do
    collection do
      post :create_multiple
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

  # Aboutnesses - destroy doesn't need embodiment nesting
  resources :aboutnesses, only: [:destroy]

  root 'home#index'
end

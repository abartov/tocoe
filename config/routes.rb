Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  get 'manifestations/show'

  get 'manifestations/approve'

  resources :tocs do
    member do
      get :browse_scans
      post :mark_pages
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

  root 'publications#search'
end

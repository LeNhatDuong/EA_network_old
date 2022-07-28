Rails.application.routes.draw do
  root 'home#index'

  resources :home, only: [:index]

  resources :charts, only: [:index] do
    collection do
      get :filter
    end
  end

  resources :networks do
    collection do
      get :manual_update
      get :update
    end
  end

  resources :gateways, only: [] do
    collection do
      get :update
      get :send_alert
    end
  end
end

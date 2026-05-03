Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # Rutas públicas
  get 'pages/about', to: 'pages#about'
  get 'doctors', to: 'doctors#index'
  get 'medical_institutes', to: 'medical_institutes#index'

  # Rutas para DOCTORES
  namespace :doctors do
    get 'dashboard', to: 'dashboard#show', as: 'dashboard'

    resource :assistant, only: [:show], controller: "assistants" do
      post :message, on: :collection
    end

    resource :doctor, only: [:show, :edit, :update], controller: "doctor"

    resources :calendars, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :hours, only: [:new, :create, :edit, :update, :destroy]
    end
    resources :hours, only: [:index]

    resources :appointments, only: [:index, :show, :edit, :update, :destroy] do
      member do
        match 'confirm', via: [:patch, :get]
        match 'cancel',  via: [:patch, :get]
        get :notes
        post :save_notes
      end
    end

    resources :patients, only: [:index, :show] do
      resources :medical_histories, only: [:new, :create, :edit, :update, :show]
    end
  end

  # Rutas para ADMINISTRADOR (Recepcionista)
  namespace :admin do
    get 'dashboard', to: 'dashboard#show', as: 'dashboard'

    resource :assistant, only: [:show], controller: "assistants" do
      post :message, on: :collection
    end

    resources :users
    resources :doctors
    resources :appointments
    resources :patients
  end

  # Rutas para GERENTE
  namespace :gerente do
    get 'dashboard', to: 'dashboard#show', as: 'dashboard'
    resources :medical_institutes
  end

  namespace :public do
    resource :assistant, only: [] do
      post :message, on: :collection
    end
  end
end

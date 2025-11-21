Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # Rutas para Visitantes (sin autenticar)
  get 'pages/about', to: 'pages#about' # "Sobre nosotros"
  get 'doctors', to: 'doctors#index' # Ver directorio de doctores
  get 'medical_institutes', to: 'medical_institutes#index' # Ver institutos cercanos

  # Rutas para Usuarios Autenticados (General)
  # Podría ser un dashboard general o redirigir según el rol
  get 'dashboard', to: 'dashboards#show'

  # Rutas Específicas para PACIENTES
  namespace :patients do
    # Dashboard del paciente
    get 'dashboard', to: 'dashboard#show', as: 'dashboard'

    # Recursos para el paciente
    resources :medical_histories, only: [:index, :show] # Ver historial médico
    resources :doctors, only: [:index, :show] # Ver doctores (sus perfiles)

    # Citas del paciente
    resources :appointments, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  end

  # Rutas Específicas para DOCTORES
  namespace :doctors do
    # Dashboard del doctor
    get 'dashboard', to: 'dashboards#show', as: 'dashboard'

    # Ver perfil del doctor (él mismo)
    resource :doctor, only: [:show, :edit, :update]

    # Gestión de Calendario y Citas
    resources :calendars, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :hours, only: [:new, :create, :edit, :update, :destroy]
    end

    # Citas (puede ser un listado general de sus citas, diferente al del paciente)
    resources :appointments, only: [:index, :show, :edit, :update, :destroy] do
      member do
        patch 'confirm' # Confirmar una cita
        patch 'cancel'  # Cancelar una cita
        # Otras acciones de gestión de citas
      end
    end

    # Historias Médicas (crear y actualizar para sus pacientes)
    resources :patients, only: [:index, :show] do # Acceso a sus pacientes
      resources :medical_histories, only: [:new, :create, :edit, :update, :show]
    end

    # Chat interno entre doctores
    # CASO DE USARLO resources :messages, only: [:index, :new, :create, :show]
  end

  # Rutas Específicas para ADMINISTRATIVOS
  namespace :admin do
    # Dashboard del administrador
    get 'dashboard', to: 'dashboards#show', as: 'dashboard'

    # Gestión de Usuarios
    resources :users # 'users' aquí se refiere a la tabla USERS, que incluye doctores, pacientes, etc.

    # Gestión de Doctores (asignar roles, institutos, etc.)
    resources :doctors

    # Gestión de Citas
    resources :appointments

    # Gestión de Pacientes
    resources :patients

    # Gestión de Institutos Médicos
    resources :medical_institutes

    # Historiales de pacientes
    resources :medical_histories, only: [:index, :show]

    # Facturas
    resources :invoices, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  end

end

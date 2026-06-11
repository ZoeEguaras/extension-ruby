Rails.application.routes.draw do
  # Excluir registrations de Devise, usamos UsersController para crear usuarios, y passwords para resetear contraseñas
  devise_for :users, skip: [:registrations, :passwords]

  # ROOT = Storefront público
  root to: 'storefront#index'

  # Storefront público (sin autenticación)
  get 'tienda', to: 'storefront#index', as: :storefront
  get 'tienda/:id', to: 'storefront#show', as: :storefront_product

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Administración
  namespace :backstore do
    resources :products do
      member do
        patch :update_stock
        patch :soft_delete
      end
    end

    resources :genres, only: [:index, :new, :create, :destroy]
    resources :users
    resources :sales, only: [:index, :new, :create, :show] do
      member do
        patch :cancel
      end
      collection do
        get :search_products
      end
    end

    # Reportes
    get "reports", to: "reports#index", as: :reports
  end
end

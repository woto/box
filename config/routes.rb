require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users
  resources :cells
  resources :devices do
    member do
      post 'status'
    end
  end
  resources :communicates
  mount Sidekiq::Web => '/sidekiq'
  root 'communicates#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end

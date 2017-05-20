Rails.application.routes.draw do
  resources :devices
  resources :communicates
  root 'communicates#index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end

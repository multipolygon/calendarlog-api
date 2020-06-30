Rails.application.routes.draw do
  root "site#home"
  
  namespace :site, path: '/' do
    get :information
    get :login
    post :login
    get :app_login
    post :logout
    get :signup
    post :signup
    get :testerror
    get :feedback
  end
  
  resource :user
  resources :password_resets, only: [:new, :create, :edit]
  
  resources :locations do
    member do
      post :restore
      post :record
      get :userlogin
    end
  end
  
  get "/(:old_id)/(:year)" => "locations#show"
end

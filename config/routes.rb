Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "pages#home"

  # --- Demo 1: Collaborative Kanban ---------------------------------------
  resource :board, only: [ :show ], controller: "boards" do
    post :reset, on: :member
    # A bare, chromeless render of the same board for the side-by-side iframe,
    # so a single visitor sees the realtime morph without opening two windows.
    get :embed, on: :member
  end

  resources :cards, only: [ :create, :update, :destroy ] do
    patch :move, on: :member
  end

  # --- Demo 2: Choose-Your-Path Story Engine ------------------------------
  # Convenience singular alias mentioned in the brief: /story -> the story list.
  get "story", to: "stories#index", as: :story_alias

  resources :stories, only: [ :index, :show ], param: :slug do
    # GET shows a scene; POST records the reader's choice then redirects.
    get  "scenes/:key", to: "scenes#show", as: :scene
    post "choices/:id", to: "choices#choose", as: :choice
  end
end

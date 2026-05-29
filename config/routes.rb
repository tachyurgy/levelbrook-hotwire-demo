Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  # ⌘K command palette — server-rendered results into a frame.
  get "command", to: "command#index", as: :command

  # --- Kanban board (centerpiece) ---------------------------------------
  resources :projects, only: [ :index, :show ], param: :slug do
    member do
      post :reset
    end
  end

  resources :issues, only: [ :show ] do
    # SortableJS drop -> PUT new column + position. Thin endpoint.
    resource :position, only: [ :update ], controller: "issues/positions"
    # Inline frame-swap edit of a single field.
    get  "field/:field", to: "issues#edit_field", as: :field
    patch "field/:field", to: "issues#update_field"
    resources :comments, only: [ :create ]
  end

  # --- Real-time chat ----------------------------------------------------
  resources :channels, only: [ :index, :show ], param: :slug do
    resources :messages, only: [ :create ]
  end

  # --- Live search / filter (debounced frame) ---------------------------
  resource :search, only: [ :show ], controller: "search"

  # --- Infinite scroll / lazy frames ------------------------------------
  resources :activities, only: [ :index ]

  # --- Live form validation ---------------------------------------------
  resources :signups, only: [ :new, :create ] do
    post :validate, on: :collection
  end
end

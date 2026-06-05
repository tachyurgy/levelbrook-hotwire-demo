Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # The switcher / portfolio front door.
  root "gallery#index"

  # ============================ Workspace =================================
  # The delivery-board app. Its dashboard lives at /workspace.
  get "workspace", to: "pages#home", as: :workspace

  # ⌘K command palette — server-rendered results into a frame.
  get "command", to: "command#index", as: :command

  resources :projects, only: [ :index, :show ], param: :slug do
    member do
      post :reset
    end
  end

  resources :issues, only: [ :show ] do
    # SortableJS drop -> PUT new column + position. Thin endpoint.
    resource :position, only: [ :update ], controller: "issues/positions"
    # Inline frame-swap edit of a single field.
    get "field/:field", to: "issues#edit_field", as: :field
    patch "field/:field", to: "issues#update_field"
    resources :comments, only: [ :create ]
  end

  # Live search / filter (debounced inline combobox frame).
  resource :search, only: [ :show ], controller: "search"

  # Infinite scroll / lazy frames.
  resources :activities, only: [ :index ]

  # Live form validation.
  resources :signups, only: [ :new, :create ] do
    post :validate, on: :collection
  end

  # ============================ Cadence (chat) ============================
  resources :channels, only: [ :index, :show ], param: :slug do
    resources :messages, only: [ :create ] do
      resource :reaction, only: [ :create ], controller: "reactions"
    end
  end

  # ============================ Ballot (polls/Q&A) ========================
  namespace :ballot do
    root "rooms#index"
    resources :rooms, only: [ :index, :show ], param: :slug do
      member { post :reset }
      resources :polls, only: [ :create ] do
        resources :votes, only: [ :create ]
      end
      resources :questions, only: [ :create ] do
        resource :upvote, only: [ :create ], controller: "upvotes"
      end
    end
  end

  # ============================ Pulse (ops dashboard) =====================
  namespace :pulse do
    root "dashboard#index"
    post "incidents/trigger", to: "incidents#trigger", as: :trigger_incident
    resources :deploys, only: [ :create ]
    resources :incidents, only: [ :update ]
  end

  # ============================ Grid (spreadsheet) ========================
  namespace :grid do
    root "sheets#index"
    resources :sheets, only: [ :index, :show ], param: :slug do
      member { post :reset }
    end
    resources :cells, only: [ :update ]
  end

  # ============================ Spindle (media) ===========================
  namespace :spindle do
    root "albums#index"
    resources :albums, only: [ :index, :show ], param: :slug
  end

  # ============================ Relay (AI streaming) =====================
  # The ai_stream flagship: a live LLM chat that streams Google Gemini tokens
  # to the browser as Vercel-AI-SDK data-stream-protocol frames, encoded by the
  # vendored `ai_stream` gem over ActionController::Live SSE.
  namespace :relay do
    root "chat#index"
    # POST a prompt; the response body streams SSE protocol frames.
    resources :messages, only: [ :create ]
  end

  # ============================ Forge (OSS playgrounds) ==================
  # Interactive, server-computed playgrounds that dogfood the vendored gems:
  # picoglob (glob -> Regexp) and fzy_score (fuzzy ranking). Each result panel
  # is a debounced Turbo Frame whose `src` carries the live inputs.
  namespace :forge do
    root "playground#index"
    get "picoglob", to: "playground#picoglob", as: :picoglob
    get "fzy",      to: "playground#fzy",      as: :fzy
  end

  # =============== LinguaGuessr "Report bad audio" ingest =================
  # Standalone API-key-protected JSON endpoint (not part of the showcase apps).
  namespace :api do
    namespace :v1 do
      resources :bad_audio_reports, only: [ :create ]
      # CORS preflight for the cross-origin POST from lingua.levelbrook.com.
      match "bad_audio_reports", to: "bad_audio_reports#preflight", via: :options
    end
  end
end

require 'resque/server'

Rails.application.routes.draw do
  constraints :subdomain => "upload" do
    resources :videos, only: [:create, :update] do
      resource :cover, only: [:update], module: :videos
    end

    get '/*any', to: redirect(subdomain: '')
    root to: redirect(subdomain: '')
  end

  devise_for :users, controllers: {
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  scope controller: :staff do
    get 'copyright', 'fairuse', 'policy', 'terms', action: :policy
    get 'donate', 'staff'
  end

  resource :services do
    post 'register', 'deregister'
  end

  # Asset Fallbacks #
  scope module: :assets, constraints: { id: /[0-9]+/ } do #*/
    scope 'avatar/:year/:month/:day/:id/', module: :users do
      resource :avatar, :thumb, :banner, only: [:show]
    end
    scope 'stream/:year/:month/:day/:id', module: :videos do
      resource :cover, :thumb, :source, :video, only: [:show]
    end
    resource :serviceworker, only: [:show]
  end

  # Videos #
  namespace :videos do
    resource :feed, only: [:edit, :update, :show]
  end
  resources :videos, except: [:destroy, :create] do
    scope module: :videos do
      resources :actions, only: [:update]
      resources :changes, only: [:index]
      resource :statistics, only: [:show]
      resource :details, :play_count, only: [:update]
      resource :download, only: [:show]
      resource :add, only: [:show, :update]
    end
  end

  # Users #
  resources :users, only: [:index, :update, :show] do
    scope module: :users do
      resources :albums, :comments, only: [:index]

      resource :hovercard, only: [:show]
      resource :banner, only: [:show, :update]
      resource :avatar, :prefs, only: [:update]

      resources :profile_columns, only: [] do
        resources :items, controller: :profile_modules, only: [:update]
      end
      resources :profile_modules, only: [:new, :create, :destroy]
    end
  end

  # Albums #
  resource :stars, only: [:show], module: :albums
  resources :albums, id: /([0-9]+).*/ do #*/
    scope module: :albums do
      resources :items, only: [:index]
      resource :order, only: [:update]
    end
  end
  namespace :albums do
    resources :items, only: [:create, :update, :destroy]
  end

  # Tags #
  resources :tags, only: [:index], id: /([0-9]+).*/ do #*/
    scope module: :tags do
      resources :actions, only: [:update], id: /([a-zA-Z]+).*/ #*/
      resources :videos, :users, :changes, only: [:index]
    end
  end
  scope :tags do
    resources :aliases, :implied, only: [:index], module: :tags

    get ':id', action: :show, controller: :tags, id: /.*/ #*/
  end

  # Filters #
  scope :filters, module: :filters do
    resource :current_filter, only: [:update]
  end
  resources :filters

  # Forums #
  resources :forum, only: [:index, :new, :create, :edit, :update, :destroy], controller: :boards, module: :forum
  namespace :forum do
    resources :badges, only: [:index]
    resources :search, only: [:index]

    # Threads #
    resources :threads, only: [:new, :create, :update, :show] do
      resource :subscribe, only: [:update]
    end
  end

  # Comments #
  resources :comments, only: [:create, :update, :destroy] do
    resource :like, only: [:update], module: :comments
  end

  # Private Messages #
  namespace :inbox do
    get '(:type)(/:tabs)', action: :show
  end

  scope module: :inbox do
    resources :messages, only: [:create, :new, :show], controller: :pm do
      resource :markread, only: [:update]
      delete ':type', action: :destroy
    end
  end

  resources :notifications, only: [:show, :index, :destroy]
  resources :search, only: [:index]
  namespace :search do
    resource :syntax, only: [:show]
  end

  # Lookup Actions #
  namespace :find do
    resources :users, :comments, :tags, only: [:index]
  end

  # Admin Actions #
  namespace :admin, controller: :admin do
    resource :transfer, only: [:update]
    resources :files, only: [:index]
    namespace :tags do
      resources :types, except: [:show, :edit]
      resources :rules, except: [:show, :edit]
    end
    resources :tags, only: [:show, :update]
    resources :sitenotices, except: [:show, :edit]
    resources :api, except: [:show], controller: :api_tokens
    resources :reindex, only: [:update]

    resource :settings, only: [] do
      put 'set/:key', action: :set
      put 'toggle/:key', action: :toggle
    end

    resources :albums, only: [:show] do
      resource :feature, only: [:update], module: :albums
    end

    namespace :videos do
      resources :unprocessed, only: [:index], controller: :unprocessed_videos
      resources :hidden, only: [:index, :destroy], controller: :hidden_videos
      resource :requeue, only: [:update], controller: :requeue_videos
      resource :thumbnail, :listing, only: [:update]
    end
    resources :videos, only: [:show, :destroy] do
      scope module: :videos do
        resource :hide, only: [:update], controller: :hidden_videos
        resource :feature, only: [:update], controller: :featured_videos
        resource :reprocess, only: [:update], controller: :unprocessed_videos
        resource :merge, only: [:update], controller: :merged_videos
        resource :thumbnail, only: [:destroy]
        resource :metadata, :moderation, only: [:update]
      end
    end

    resources :users, only: [:show,:destroy] do
      resources :badges, :roles, only: [:update], module: :users
    end

    # Reporting #
    resource :reports, only: [:destroy]
    resources :reports, only: [:new, :show, :index, :create] do
      put '/:state' => :update
    end

    scope module: :forum do
      resources :badges, except: [:show, :edit]
      resources :threads, only: [:destroy] do
        resource :pin, :lock, :move, only: [:update], module: :threads
      end
    end

    root 'admin#index'
  end

  # Embeds #
  resource :oembed, only: [:show], module: :embed
  namespace :embed do
    resource :twitter, only: [:show]
    get ':id' => 'videos#show'
  end

  constraints CanAccessJobs do
    mount Resque::Server.new, at: '/admin/resque'
  end

  # API #
  namespace :api do
    resource :bbcode, :html, :youtube, only: [:show]
    resources :videos, only: [:index, :show]
  end

  # External redirects #
  scope module: :external do
    resource :watch, only: [:show]
  end

  # Short links #
  get 'profile/:id' => 'users#show', constraints: { id: /([0-9]+).*/ }#*/
  get '/:id(-:safe_title)' => 'videos#show', constraints: { id: /([0-9]+)/ }
  get '/:id' => 'forum/boards#show'
  get '/:board_name/:id' => 'forum/threads#show'

  # Home #
  root 'welcome#index'
end

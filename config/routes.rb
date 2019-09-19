require 'resque/server'

Rails.application.routes.draw do
  constraints :subdomain => "" do
    devise_for :users, controllers: {
      passwords: 'users/passwords',
      registrations: 'users/registrations',
      sessions: 'users/sessions'
    }

    scope controller: :staff do
      scope action: :policy do
        get 'copyright'
        get 'fairuse'
        get 'policy'
        get 'terms'
      end

      get 'donate'
      get 'staff'
    end

    resource :services do
      post 'register'
      post 'deregister'
    end

    # Asset Fallbacks #
    scope controller: :imgs, constraints: { id: /[0-9]+/ } do #*/
      get 'cover/:id(-:small)', action: :cover
      get 'avatar/:id(-:small)', action: :avatar
      get 'banner/:id', action: :banner
      get 'stream/:id', action: :stream
      get 'serviceworker', action: :service
    end

    resource :feed, only: [:edit, :update, :show]
    resources :badges, only: [:index]

    # Videos #
    get 'upload' => 'videos#new'
    resources :videos, except: [:new, :destroy, :create] do
      scope module: :videos do
        resources :actions, only: [:update]
        resource :details, only: [:update]
        resource :download, only: [:show]
        resources :changes, only: [:index]
      end

      put 'add' => 'albumitems#toggle'
    end

    # Users #
    get 'profile/:id' => 'users#show', constraints: { id: /([0-9]+).*/ }#*/
    resources :users, only: [:index, :update] do
      scope module: :users do
        resources :uploads, only: [:index]
        resources :videos, only: [:index]
        resources :albums, only: [:index]
        resources :comments, only: [:index]

        resource :hovercard, only: [:show]
        resource :banner, only: [:show, :update]
        resource :avatar, only: [:update]
        resource :prefs, only: [:update]
      end
    end

    # Albums #
    get 'stars' => 'albums#starred'
    resources :albums, id: /([0-9]+).*/ do #*/
      get 'items' => 'album_item#index'
      patch 'order'
    end

    resources :albumitems, only: [:create, :update, :destroy]

    # Tags #
    resources :tags, only: [:index], id: /([0-9]+).*/ do #*/
      scope module: 'tags' do
        scope controller: :actions do
          put 'hide'
          put 'spoiler'
          put 'watch'
        end

        resources :videos, only: [:index]
        resources :users, only: [:index]
        resources :changes, only: [:index]
      end
    end
    scope :tags do
      scope module: 'tags' do
        resources :aliases, only: [:index]
        resources :implied, only: [:index]
      end

      get ':id', action: :show, controller: :tags, id: /.*/ #*/
    end

    # Forums #
    resources :forum, only: [:index, :new, :create, :edit, :update, :destroy], controller: :boards, module: :forum
    namespace :forum do
      resources :search, only: [:index]

      # Threads #
      resources :threads, only: [:new, :create, :update] do
        resource :subscribe, only: [:update]
        get '(/:order)', action: :show
      end
    end

    # Comments #
    resources :comments, only: [:create, :update, :destroy] do
      put 'like'
    end

    # Private Messages #
    namespace :inbox do
      get '(:type)(/:tabs)', action: :show
    end

    resources :messages, only: [:create, :new, :show], controller: :pm do
      put 'markread'
      delete ':type', action: :destroy
    end

    # Notifications #
    resources :notifications, only: [:index, :destroy]

    # Technically shouldn't be a get since it has a side-effect, but eh.
    # A bit of a trick to get notifications to mark themselves read when you click on them.
    get 'review' => 'notifications#view'

    resources :search, only: [:index]

    # Lookup Actions #
    namespace :find do
      resources :users, only: [:index]
      resources :comments, only: [:index]
      resources :tags, only: [:index]
    end

    # Admin Actions #
    namespace :admin, controller: :admin do
      resource :transfer, only: [:update]
      resources :files, only: [:index]
      namespace :verify do
        resource :users, only: [:update]
        resource :videos, only: [:update]
      end

      resource :settings, only: [] do
        put 'set/:key', action: :set
        put 'toggle/:key', action: :toggle
      end

      resources :albums, only: [:show] do
        put 'feature'
      end

      namespace :videos do
        resources :unprocessed, only: [:index], controller: :unprocessed_videos
        resources :hidden, only: [:index, :destroy], controller: :hidden_videos
        resource :requeue, only: [:update], controller: :requeue_videos
        resource :thumbnail, only: [:update]
      end

      resources :videos, only: [:show, :destroy] do
        scope module: :videos do
          resource :hide, only: [:update], controller: :hidden_videos
          resource :feature, only: [:update], controller: :featured_videos
          resource :reprocess, only: [:update], controller: :unprocessed_videos
          resource :merge, only: [:update], controller: :merged_videos
          resource :thumbnail, only: [:destroy]
          resource :metadata, only: [:update]
          resource :moderation, only: [:update]
        end
      end

      resources :tags, only: [:show, :update]
      resources :tagtypes, except: [:show, :edit]
      resources :badges, except: [:show, :edit]
      resources :userbadges, only: [:update]
      resources :sitenotices, except: [:show, :edit]
      resources :api, except: [:show], controller: :api_tokens
      resources :users, only: [:show] do
        resources :badges, only: [:update], controller: :user_badges
        resources :roles, only: [:update]
      end

      # Reporting #
      resources :reports, only: [:new, :show, :index, :create] do
        put '/:state' => :update
      end
      resource :reports, only: [] do
        post 'closeall' => :close_all
      end

      resources :threads, only: [:destroy] do
        put 'pin'
        put 'lock'
        put 'move'
      end

      resources :reindex, only: [:update]

      root 'admin#view'
    end

    # Embeds #
    namespace :embed do
      get 'twitter' => 'twitter#show'
      get ':id' => 'videos#show'
    end
    get 'oembed' => 'embed/videos#oembed'

    constraints CanAccessJobs do
      mount Resque::Server.new, at: '/admin/resque'
    end

    # API #
    namespace :api do
      get 'bbcode' => 'bbcode#html_to_bbcode'
      get 'html' => 'bbcode#bbcode_to_html'
      get 'youtube' => 'youtube#show'

      resources :videos, only: [:index, :show]
    end

    # Short links #
    get '/:id(-:safe_title)' => 'videos#show', constraints: { id: /([0-9]+)/ }
    get '/:id' => 'forum/boards#show'
    get '/:board_name/:id' => 'forum/threads#show'
  end
  constraints :subdomain => "upload" do
    resources :videos, only: [:create, :update] do
      scope module: :videos do
        resource :cover, only: [:update]
      end
    end

    get '/*any', to: redirect(subdomain: '')
    root to: redirect(subdomain: '')
  end

  # Home #
  root 'welcome#index'
end

require 'resque/server'

Rails.application.routes.draw do
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
  scope controller: :imgs, constraints: { id: /[0-9]+/ } do
    get 'cover/:id(-:small)', action: :cover
    get 'avatar/:id(-:small)', action: :avatar
    get 'banner/:id', action: :banner
    get 'stream/:id', action: :stream
    get 'serviceworker', action: :service
  end
  
  # Feeds #
  resource :feed, only: [:edit, :update, :show]
  
  # Badges #
  resources :badges, only: [:index]
  
  # Videos #
  get 'upload' => 'videos#new'
  resources :videos, except: [:new, :destroy] do
    put 'like'
    put 'dislike'
    put 'star'
    patch 'cover' => 'videos#cover'
    patch 'details' => 'videos#details'
    
    get 'changes' => 'history#index'
    get 'download'
    
    put 'add' => 'albumitems#toggle'
  end
  
  # Users #
  get 'profile/:id' => 'users#show', constraints: { id: /([0-9]+).*/ }
  resources :users, only: [:index, :update] do
    get 'uploads'
    get 'videos'
    get 'albums'
    get 'comments'
    
    get 'hovercard'
    get 'banner'
    put 'prefs'
    patch 'avatar' => 'users#set_avatar'
    patch 'banner' => 'users#set_banner'
  end
  
  # Albums #
  get 'stars' => 'albums#starred'
  resources :albums, id: /([0-9]+).*/ do # /
    get 'items' => 'album_item#index'
    patch 'order'
  end
  
  resources :albumitems, only: [:create, :update, :destroy]
  
  # Tags #
  resources :tags, only: [:index], id: /([0-9]+).*/ do
    put 'hide'
    put 'spoiler'
    put 'watch'
    
    get 'videos'
    get 'users'
    get 'changes', controller: :history, action: :tag
  end
  resource :tags do
    get 'aliases'
    get 'implied'
    
    get ':name', action: :show, constraints: { name: /.*/ }
  end
  
  # Forums #
  resources :forum, only: [:index, :new, :create, :edit, :update, :destroy], controller: 'forum/boards'
  namespace :forum do
    get 'search' => 'search#index'
  end
  
  # Threads #
  resources :threads, only: [:show, :new, :create, :update] do
    put 'subscribe'
    get '/:order', action: :show
  end
  
  # Comments #
  resources :comments, only: [:create, :update, :destroy] do
    put 'like(/:incr)', action: 'like'
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
  
  # Main Search #
  get 'search' => 'search#index'
  
  # Lookup Actions #
  namespace :find do
    get 'users' => 'users#find'
    get 'comments' => 'comment#find'
    get 'tags' => 'tags#find'
  end
  
  # Admin Actions #
  namespace :admin, controller: :admin do
    post 'transfer'
    post 'verify'
    
    get 'files' => 'files#index'
    
    resource :settings, only: [] do
      put 'set/:key', action: :set
      put 'toggle/:key', action: :toggle
    end
    
    resources :albums, only: [:show] do
      put 'feature'
    end
    
    resource :videos, only: [] do
      get 'hidden'
      get 'unprocessed'
      
      post 'hidden/drop', action: :batch_drop
      post 'requeue'
    end
    
    resources :videos, only: [:show, :destroy] do
      put 'hide'
      put 'feature'
      put 'reprocess'
      put 'resetthumb'
      put 'merge'
      put 'metadata'
    end
    
    resources :tags, only: [:show, :update]
    resources :tagtypes, except: [:show, :edit]
    resources :badges, except: [:show, :edit]
    resources :userbadges, only: [:update]
    resources :sitenotices, except: [:show, :edit]
    resources :api, except: [:show, :edit], controller: :api_tokens
    resources :users, only: [:show] do
      resources :badges, only: [:update], controller: :user_badges
      resources :roles, only: [:update]
    end
    
    # Reporting #
    resources :reports, only: [:new, :show, :index, :create] do
      put "/:state" => :update
    end
    resource :reports, only: [] do
      post "closeall" => :close_all
    end
    
    resources :threads, only: [:destroy] do
      put 'pin'
      put 'lock'
      put 'move'
    end
    
    put 'rethumb'
    put ':table/reindex', action: :reindex
    
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
  
  namespace :api do
    # API #
    get 'bbcode' => 'bbcode#html_to_bbcode'
    get 'html' => 'bbcode#bbcode_to_html'
    
    resources :videos, only: [:index, :show]
    
    get 'youtube' => 'youtube#show'
  end
  
  # Short links #
  get '/:id(-:safe_title)' => 'videos#show', constraints: { id: /([0-9]+)/ }
  get '/:id' => 'forum/boards#show'
  
  # Home #
  root 'welcome#index'
end

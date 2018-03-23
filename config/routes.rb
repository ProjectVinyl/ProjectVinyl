require 'resque/server'

Rails.application.routes.draw do
  devise_for :users, controllers: {
    passwords: 'users/passwords',
    registrations: 'users/registrations'
  }
    
  scope controller: :staff do
    scope action: :copyright do
      get 'copyright'
      get 'fairuse'
    end
    
    scope action: :policy do
      get 'policy'
      get 'terms'
    end
    
    get 'donate'
    get 'staff'
  end
  
  # Popup Windows #
  namespace :ajax do
    get 'login' => 'sessions#login'
    get 'donate' => 'staff#donate'
    get 'videos/:id' => 'videos#go_next'
  end
  
  # Asset Fallbacks #
  
  get 'cover/:id(-:small)' => 'imgs#cover', constraints: { id: /[0-9]+/ } # /
  get 'avatar/:id(-:small)' => 'imgs#avatar', constraints: { id: /[0-9]+/ } # /
  get 'banner/:id' => 'imgs#banner'
  get 'stream/:id' => 'imgs#stream', constraints: { id: /.*/ } # /
  
  # Filters #
  resource :filters, only: [:edit, :update], controller: :feed
  
  # Feeds #
  resource :feed, only: [:show], controller: :feed do
    get 'page'
  end
  
  # Badges #
  get 'badges' => 'badge#index'
  
  # Videos #
  get 'upload' => 'videos#new'
  
  resources :videos, except: [:create, :new, :destroy], id: /([0-9]+).*/ do # /
    put 'like'
    put 'dislike'
    put 'star'
    patch 'cover' => 'videos#cover'
    patch 'details' => 'videos#details'
    
    get 'changes' => 'history#index'
    get 'download'
    
    put 'add' => 'album_item#toggle'
  end
  
  # Users #
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
  get 'profile/:id' => 'users#show', constraints: { id: /([0-9]+).*/ } # /
  
  # Albums #
  resources :albums, id: /([0-9]+).*/ do # /
    get 'items' => 'album_item#index'
    patch 'order'
  end
  get 'stars' => 'albums#starred'
  
  resources :albumitems, only: [:create, :update, :destroy], controller: :album_item
  
  # Tags #
  resources :tags, only: [:index], id: /([0-9]+).*/ do # /
    get 'videos'
    get 'users'
    
    put 'hide'
    put 'spoiler'
    put 'watch'
  end
  scope :tags, controller: :tags do
    get 'aliases'
    get 'implied'
    get ':name', action: :show, constraints: { name: /.*/ } # /
  end
  
  # Forums #
  namespace :forum, id: /[^\.\/]+/ do # /
    get 'search' => 'search#index'
    get ':id' => 'board#view'
    root 'board#index'
  end
  
  # Boards/Categories #
  
  resources :boards, only: [:index, :new, :create, :destroy], controller: 'forum/board'
  
  # Threads #
  get 'thread/:id' => 'thread#view', constraints: { id: /([0-9]+).*/ } # /
  resources :threads, only: [:new, :create, :update], controller: :thread do
    put 'subscribe'
  end
  
  # Comments #
  resources :comments, only: [:create, :update, :destroy], controller: :comment do
    put 'like(/:incr)', action: 'like'
  end
  get 'comments/:thread_id/:order' => 'comment#page'
  
  # Private Messages #
  scope 'inbox', controller: :inbox do
    get ':type/tabs', action: :tab
    get '(:type)', action: :show
  end
  
  resources :message, only: [:create, :new, :show], controller: :pm do
    put 'markread'
    delete ':type', action: :destroy
  end
  
  # Notifications #  
  resources :notifications, only: [:index, :destroy], controller: :notification
  
  # Technically shouldn't be a get since it has a side-effect, but eh.
  # A bit of a trick to get notifications to mark themselves read when you click on them.
  get 'review' => 'notification#view'
  get 'ajax/notifications' => 'ajax/notification#view'
  
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
    
    resources :albums, only: [:show], controller: :album do
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
    resources :tagtypes, except: [:show, :edit], controller: :tag_type
    resources :sitenotices, except: [:show, :edit], controller: :site_notice
    resources :users, only: [:show] do
      resources :badges, only: [:update]
      resources :roles, only: [:update]
    end
    
    # Reporting #
    resources :reports, only: [:new, :show, :index, :create], controller: :report
    
    resources :threads, only: [:destroy], controller: :thread do
      put 'pin'
      put 'lock'
      put 'move'
    end
    
    put ':table/reindex', action: :reindex
    
    root 'admin#view'
  end
  
  # Embeds #
  namespace :embed do
    get 'twitter' => 'twitter#view'
    get ':id' => 'videos#view'
  end
  get 'oembed' => 'embed/videos#oembed'
  
  constraints CanAccessJobs do
    mount Resque::Server.new, at: '/admin/resque'
  end
  
  namespace :api do
    # API #
    get 'bbcode' => 'bbcode#html_to_bbcode'
    get 'html' => 'bbcode#bbcode_to_html'
  end
  
  # Short link #
  get '/:id(-:safe_title)' => 'videos#show', constraints: { id: /([0-9]+)/ } # /
  
  # Home #
  get '/' => 'welcome#index'
  root 'welcome#index'
end

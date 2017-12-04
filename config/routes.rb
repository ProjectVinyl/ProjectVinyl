require 'resque/server'

Rails.application.routes.draw do
  devise_for :users
  
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
    get 'login' => 'session#login'
    get 'donate' => 'staff#donate'
    get 'videos/:id' => 'video#go_next'
  end
  
  # Asset Fallbacks #
  
  get 'cover/:id(-:small)' => 'imgs#cover'
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
  get 'upload' => 'video#new'
  get 'download/:id' => 'video#download'
  
  resources :videos, except: [:create, :new, :destroy], controller: :video, id: /([0-9]+).*/ do # /
    put 'like'
    put 'dislike'
    put 'star'
    patch 'cover' => 'video#cover'
    patch 'details' => 'video#details'
    
    get 'changes' => 'history#index'
    
    put 'add' => 'album_item#toggle'
  end
  
  # Users #
  resources :users, only: [:index, :update], controller: :artist do
    get 'uploads'
    get 'videos'
    get 'albums'
    
    get 'hovercard'
    get 'banner'
    put 'prefs'
    patch 'avatar' => 'artist#set_avatar'
    patch 'banner' => 'artist#set_banner'
  end
  get 'profile/:id' => 'artist#view', constraints: { id: /([0-9]+).*/ } # /
  
  # Albums #
  resources :albums, except: [:show], controller: :album do
    get 'items' => 'album_item#index'
    patch 'order'
  end
  get 'album/:id' => 'album#show', constraints: { id: /([0-9]+).*/ } # /
  get 'stars' => 'album#starred'
  
  resources :albumitems, only: [:create, :update, :destroy], controller: :album_item
  
  # Tags #
  resources :tags, only: [:index], controller: :tag, id: /([0-9]+).*/ do # /
    get 'videos'
    get 'users'
    
    put 'hide'
    put 'spoiler'
    put 'watch'
  end
  scope 'tags', controller: :tag do
    get ':name', action: 'view', constraints: { name: /.*/ } # /
  end
  
  # Forums #
  namespace :forum, id: /[^\.\/]+/ do # /
    get 'search' => 'search#index'
    get ':id' => 'board#view'
    get ':board_id/threads' => 'board#threads'
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
  get 'search.json' => 'search#page'
  get 'search' => 'search#index'
  
  # Lookup Actions #
  namespace :find do
    get 'users' => 'user#find'
    get 'comments' => 'comment#find'
    get 'tags' => 'tag#find'
  end
  
  # Admin Actions #
  namespace :admin, controller: :admin do
    post 'transfer'
    post 'verify'
    
    get 'files' => 'files#index'
    
    resources :albums, only: [:show], controller: :album do
      put 'feature'
    end
    
    resources :videos, only: [:show, :destroy], controller: :video do
      put 'hide'
      put 'feature'
      put 'reprocess'
      put 'resetthumb'
      put 'merge'
      put 'metadata'
    end
    
    resource :videos, only: [], controller: :video do
      get 'hidden'
      get 'unprocessed'
      
      post 'hidden/drop', action: :batch_drop
      post 'requeue'
    end
    
    resources :tags, only: [:show, :update], controller: :tag
    resources :tagtypes, except: [:show, :edit], controller: :tag_type
    resources :sitenotices, except: [:show, :edit], controller: :site_notice
    resources :users, only: [:show], controller: :user do
      put 'badges/:id' => 'user#toggle_badge'
      put 'roles/:id' => 'user#role'
    end
    
    # Reporting #
    resources :reports, only: [:new, :show, :index], controller: :report
    
    resources :threads, only: [], controller: :thread do
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
    get ':id' => 'video#view'
  end
  get 'oembed' => 'embed/video#oembed'
  
  constraints CanAccessJobs do
    mount Resque::Server.new, at: '/admin/resque'
  end
  
  namespace :api do
    # API #
    get 'bbcode' => 'bbcode#html_to_bbcode'
    get 'html' => 'bbcode#bbcode_to_html'
  end
  
  # Short link #
  get '/:id' => 'video#show', constraints: { id: /([0-9]+).*/ } # /
  
  # Home #
  get '/' => 'welcome#index'
  root 'welcome#index'
end

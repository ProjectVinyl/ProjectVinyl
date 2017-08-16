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
  end
  
  # Asset Fallbacks #
  
  get 'cover/:id(-:small)' => 'imgs#cover'
  get 'avatar/:id(-:small)' => 'imgs#avatar', constraints: { id: /[0-9]+/ } #/
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
  
  get 'view/:id' => 'video#view', constraints: { id: /([0-9]+).*/ } # /
  get 'ajax/view/:id' => 'video#go_next'
    
  resources :videos, except: [:update, :new, :show, :destroy], controller: :video do
    put 'like'
    put 'dislike'
    put 'star'
    patch 'cover(/:async)' => 'video#cover'
    patch 'details'
    
    get 'changes' => 'history#index'
    get 'changes/page' => 'history#page'
    
    put 'add' => 'album_item#toggle'
  end
  scope 'videos', controller: :video do
    get 'page'
    patch ':id(/:async)', action: :update
    put '(/:async)', action: :create
    post '(/:async)', action: :create
  end
  
  # Users #
  get 'profile/:id' => 'artist#view', constraints: { id: /([0-9]+).*/ } # /
  
  resource :users, only: [], controller: :artist do
    get 'page'
    put 'prefs'
    patch 'avatar(/:async)' => 'artist#set_avatar'
    patch 'banner(/:async)' => 'artist#set_banner'
  end
  resources :users, only: [:index, :update], controller: :artist do
    get 'hovercard'
    get 'banner'
  end
  
  # Albums #
  resources :albums, controller: :album do
    get 'items' => 'album_item#index'
    patch 'order'
  end
  get 'stars' => 'album#starred'
  get 'albums/page' => 'album#page'
  
  resources :albumitems, only: [:create, :update, :destroy], controller: :album_item
  
  # Tags #
  resources :tags, only: [:index], controller: :tag do
    get 'videos'
    get 'users'
    
    put 'hide'
    put 'spoiler'
    put 'watch'
  end
  scope 'tags', controller: 'tag' do
    get 'page'
    get ':name' => 'tag#view', constraints: { name: /.*/ } # /
  end
  
  # Forums #
  namespace :forum do
    get 'search' => 'search#index'
    get 'search/page' => 'search#page'
    get ':id' => 'board#view'
    root 'board#index'
  end
  
  # Boards/Categories #
  
  get 'boards/page' => 'forum/board#page'
  resources :boards, only: [:new, :create, :destroy], controller: :board
  
  # Threads #
  get 'thread/:id' => 'thread#view', constraints: { id: /([0-9]+).*/ } # /
  resources :threads, only: [:new, :create, :update], controller: :thread do
    get 'page'
    put 'subscribe'
  end
  
  # Comments #
  resources :comments, only: [:create, :update, :destroy], controller: :comment do
    put 'like(/:incr)', action: 'like'
  end
  get 'comments/:thread_id/:order/page' => 'comment#page'
  
  # Private Messages #
  scope 'inbox', controller: :inbox do
    get ':type/page', action: :page
    get ':type/tab', action: :tab
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
  get 'search/page' => 'search#page'
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
    
    get 'files/page' => 'files#page'
    get 'files' => 'files#index'
    
    resources :albums, only: [:show], controller: :album do
      put 'feature'
    end
    
    resources :videos, only: [:show, :destroy] do
      put 'hide'
      put 'feature'
    end
    
    resource :videos, only: [], controller: :video do
      get 'hidden/page', action: :hidden
      get 'unprocessed/page', action: :unprocessed
      
      post 'hidden/drop', action: :batch_drop
      post 'requeue'
      
      put 'merge'
      put 'reprocess'
      put 'resetthumb'
      put 'metadata'
    end
    
    resources :tags, only: [:show, :update], controller: :tag
    resources :tagtypes, except: [:show, :edit], controller: :tag_type
    resources :sitenotices, except: [:show, :edit], controller: :site_notice
    resources :users, only: [:show], controller: :user do
      put 'badges/:id' => 'user#toggle_badge'
      put 'roles/:id' => 'user#role'
    end
    
    # Reporting #
    resources :reports, only: [:new, :show], controller: :report
    get 'reports/page' => 'report#page'
    post 'reports/:id(/:async)' => 'report#create'
    
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
  get '/:id' => 'video#view', constraints: { id: /([0-9]+).*/ } # /
  
  # Home #
  get '/' => 'welcome#index'
  root 'welcome#index'
end

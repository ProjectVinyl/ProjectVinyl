require 'resque/server'

Rails.application.routes.draw do
  devise_for :users
  
  get 'stars' => 'album#starred'
  
  get 'staff' => 'staff#index'
  get 'copyright' => 'staff#copyright'
  get 'fairuse' => 'staff#copyright'
  get 'policy' => 'staff#policy'
  get 'terms' => 'staff#policy'
  get 'donate' => 'staff#donate'
  
  # Popup Windows #
  namespace :ajax do
    get 'login' => 'session#login'
    get 'donate' => 'staff#donate'
  end
  
  # Asset Fallbacks #
  get 'cover/:id-small' => 'imgs#thumb'
  get 'cover/:id' => 'imgs#cover'
  get 'avatar/:id-small' => 'imgs#avatar', constraints: { id: /[0-9]+/ }
  get 'avatar/:id' => 'imgs#avatar', constraints: { id: /[0-9]+/ }
  get 'banner/:id' => 'imgs#banner'
  get 'stream/:id' => 'imgs#stream', constraints: { id: /.*/ }
  
  # Filters #
  get 'filters' => 'feed#edit'
  patch 'filters' => 'feed#update'
  
  # Feeds #
  get 'feed/page' => 'feed#page'
  get 'feed' => 'feed#view'
  
  # Badges #
  get 'badges' => 'badge#index'
  
  # Videos #
  get 'videos/page' => 'video#page'
  get 'videos' => 'video#index'
  
  get 'view/:id' => 'video#view', constraints: { id: /([0-9]+).*/ }
  get 'ajax/view/:id' => 'video#go_next'
  
  get 'upload' => 'video#new'
  get 'download/:id' => 'video#download'
  
  get 'videos/:id/edit' => 'video#edit'
  get 'videos/:id/changes/page' => 'history#page'
  get 'videos/:id/changes' => 'history#index'
  
  post 'videos/:id/star' => 'video#star'
  post 'videos/:id/like(/:incr)' => 'video#upvote'
  post 'videos/:id/dislike(/:incr)' => 'video#downvote'
  post 'videos/:id/add' => 'album_item#toggle'
  
  patch 'videos/:id/cover/:async' => 'video#update_cover'
  patch 'videos/:id/cover' => 'video#update_cover'
  patch 'videos/:id/details' => 'video#patch'
  patch 'videos/:id/:async' => 'video#update'
  patch 'videos/:id' => 'video#update'
  
  post 'videos/:async' => 'video#create'
  post 'videos' => 'video#create'
  
  # Users #
  get 'profile/:id' => 'artist#view', constraints: { id: /([0-9]+).*/ }
  
  get 'users/page' => 'artist#page'
  put 'users/prefs' => 'artist#update_prefs'
  get 'users/:id/hovercard' => 'artist#card'
  get 'users/:id/banner' => 'artist#banner'
  get 'users' => 'artist#index'
  
  patch 'users/avatar/:async' => 'artist#set_avatar'
  patch 'users/avatar' => 'artist#set_avatar'
  patch 'users/banner/:async' => 'artist#set_banner'
  patch 'users/banner' => 'artist#set_banner'
  patch 'users/:id' => 'artist#update'
  
  # Albums #
  get 'album/:id' => 'album#view'
  
  get 'albums/page' => 'album#page'
  get 'albums' => 'album#index'
  get 'albums/new' => 'album#new'
  get 'albums/:id/edit' => 'album#edit'
  get 'albums/:id/items' => 'album_item#index'
  post 'albums' => 'album#create'
  patch 'albums/:id' => 'album#update_ordering'
  put 'albums/:id' => 'album#update'
  delete 'albums/:id' => 'album#destroy'
  
  post 'albumitems' => 'album_item#create'
  patch 'albumitems/:id' => 'album_item#update'
  delete 'albumitems/:id' => 'album_item#destroy'
  
  # Tags #
  get 'tags' => 'tag#index'
  get 'tags/page' => 'tag#page'
  
  get 'tags/:name', to: 'tag#view', constraints: { name: /.*/ }
  
  get 'tags/:id/videos' => 'tag#videos'
  get 'tags/:id/users' => 'tag#users'
  
  put 'tags/:id/hide' => 'tag#hide'
  put 'tags/:id/spoiler' => 'tag#spoiler'
  put 'tags/:id/watch' => 'tag#watch'
  
  # Forums #
  get 'forum' => 'board#index'
  get 'forum/search' => 'thread#search'
  get 'forum/search/page' => 'thread#page_search'
  
  # Boards/Categories #
  get 'forum/:id' => 'board#view'
  
  get 'boards/page' => 'board#page'
  get 'boards/new' => 'board#new'
  post 'boards' => 'board#create'
  delete 'boards/:id' => 'board#destroy'
  
  # Threads #
  get 'thread/:id' => 'thread#view', constraints: { id: /([0-9]+).*/ }
  
  get 'threads/:id/page' => 'thread#page'
  get 'threads/new' => 'thread#new'
  put 'threads/:id/subscribe' => 'thread#subscribe'
  post 'threads' => 'thread#create'
  patch 'threads/:id' => 'thread#update'
  
  # Comment #
  post 'comments' => 'comment#create'
  patch 'comments/:id' => 'comment#update'
  delete 'comments/:id' => 'comment#destroy'
  
  post 'comments/like/:id(/:incr)' => 'comment#like'
  get 'comments/:thread_id/:order/page' => 'comment#page'
  
  # Private Messages #
  get 'messages/:type/tab' => 'pm#tab'
  get 'messages/:type/page' => 'pm#page'
  get 'messages/:type' => 'pm#index'
  get 'messages' => 'pm#index'
  
  get 'message/:id' => 'pm#view'
  get 'message/new' => 'pm#new'
  post 'message' => 'pm#create'
  patch 'message/:id/markread' => 'pm#mark_read'
  delete 'message/:id/:type' => 'pm#destroy'
  
  # Notifications #
  get 'notifications' => 'notification#index'
  get 'ajax/notifications' => 'ajax/notification#view'
  
  # Technically shouldn't be a get since it has a side-effect, but eh.
  # A bit of a trick to get notifications to mark themselves read when you click on them.
  get 'review' => 'notification#view'
  delete 'notifications/:id' => 'notification#destroy'
  
  # Main Search #
  namespace :search do
    get 'page' => 'search#page'
    root 'search#index'
  end
  
  # Lookup Actions #
  namespace :find do
    get 'users' => 'user#find'
    get 'comments' => 'comment#find'
    get 'tags' => 'tag#find'
  end
  
  # Admin Actions #
  namespace :admin do
    put 'transfer' => 'admin#transfer_item'
    
    get 'files/page' => 'files#page'
    get 'files' => 'files#index'
    
    get 'albums/:id' => 'admin#album'
    post 'albums/:id/feature' => 'album#toggle_featured'
    
    get 'videos/hidden/page' => 'video#hidden'
    get 'videos/unprocessed/page' => 'video#unprocessed'
    get 'videos/:id' => 'video#view'
    post 'videos/hidden/drop' => 'video#batch_drop'
    post 'videos/:id/hide' => 'video#visibility'
    post 'videos/:id/feature' => 'video#toggle_featured'
    put 'videos/merge' => 'video#merge'
    put 'videos/reprocess' => 'video#reprocess'
    put 'videos/resetthumb' => 'video#extract_thumbnail'
    put 'videos/metadata' => 'video#populate'
    delete 'videos/:id' => 'video#destroy'
    
    post 'verify' => 'admin#verify_integrity'
    post 'requeue' => 'video#rebuild_queue'
    
    get 'tags/:id' => 'tag#view'
    patch 'tags/:id' => 'tag#update'
    
    get 'tagtypes' => 'tag_type#index'
    get 'tagtypes/new' => 'tag_type#new'
    post 'tagtype/create' => 'tag_type#create'
    patch 'tagtypes/:id' => 'tag_type#update'
    delete 'tagtypes/:id' => 'tag_type#destroy'
    
    get 'sitenotices' => 'site_notice#index'
    get 'sitenotices/new' => 'site_notice#new'
    post 'sitenotices' => 'site_notice#create'
    patch 'sitenotices/:id' => 'site_notice#update'
    delete 'sitenotices/:id' => 'site_notice#delete'
    
    get 'users/:id' => 'user#view'
    post 'users/:id/badges/:badge' => 'user#toggle_badge'
    post 'users/:id/roles/:role' => 'user#role'
    
    # Reporting #
    get 'reports/page' => 'report#page'
    get 'reports/:id/new' => 'report#new'
    get 'reports/:id' => 'report#view'
    post 'reports/:id/:async' => 'report#create'
    post 'reports/:id' => 'report#create'
    
    post 'threads/:id/pin' => 'thread#pin'
    post 'threads/:id/lock' => 'thread#lock'
    post 'threads/:id/move' => 'thread#move'
    
    put ':table/reindex' => 'admin#reindex'
    
    root 'admin#view'
  end
  
  # Embeds #
  namespace :embed do
    get 'twitter' => 'twitter#view'
    get ':id' => 'video#view'
  end
  get 'oembed' => 'embed/video#oembed'
  
  constraints CanAccessJobs do
    mount Resque::Server.new, at: "/admin/resque"
  end
  
  namespace :api do
    # API #
    get 'videos' => 'video#find'
    get 'videos/:id' => 'video#details'
    post 'videos/:id' => 'video#update'
  end
  
  # Short link #
  get '/:id' => 'video#view', constraints: { id: /([0-9]+).*/ }
  
  # Home #
  get '/' => 'welcome#index'
  root 'welcome#index'
end

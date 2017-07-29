require 'resque/server'

Rails.application.routes.draw do
  devise_for :users
  put 'users/prefs' => 'artist#update_prefs'
  get 'ajax/login' => 'ajax#login'
  
  get 'stars' => 'album#starred'
  get 'search/page' => 'search#page'
  get 'search' => 'search#index'
  
  get 'staff' => 'staff#index'
  
  get 'copyright' => 'staff#copyright'
  get 'fairuse' => 'staff#copyright'
  get 'policy' => 'staff#policy'
  get 'terms' => 'staff#policy'
  
  get 'badges' => 'badge#index'
  
  get 'donate' => 'staff#donate'
  get 'ajax/donate' => 'ajax#donate'
  
  # Admin Actions #
  namespace :admin do
    get 'files/page' => 'admin#morefiles'
    get 'files' => 'admin#files'
    
    get 'album/:id' => 'admin#album'
    
    post 'album/feature' => 'album#toggle_featured'
    
    get 'artist/:id' => 'admin#artist'
    get 'tag/:id' => 'admin#tag'
    
    put 'transfer' => 'admin#transfer_item'
    put 'reindex/:table' => 'admin#reindex'
    
    get 'video/:id' => 'video#view'
    
    put 'video/reprocess' => 'video#reprocess'
    put 'video/resetthumb' => 'video#extract_thumbnail'
    put 'video/merge' => 'video#merge'
    put 'video/metadata' => 'video#populate'
    
    get 'videos/hidden/page' => 'video#hidden'
    get 'videos/unprocessed/page' => 'video#unprocessed'
    
    post 'verify' => 'admin#verify_integrity'
    post 'requeue' => 'video#rebuild_queue'
    
    post 'hidden/drop' => 'admin#batch_drop_videos'
    
    get 'tagtypes' => 'genre#view'
    get 'tagtypes/new' => 'genre#new'
    post 'tagtype/create' => 'genre#create'
    patch 'tagtypes' => 'genre#update'
    delete 'tagtypes/:id' => 'genre#delete'
    
    get 'sitenotices' => 'site_notice#view'
    get 'sitenotices/new' => 'site_notice#new'
    post 'sitenotices' => 'site_notice#create'
    patch 'sitenotices' => 'site_notice#update'
    delete 'sitenotices/:id' => 'site_notice#delete'
    
    post 'video/hide' => 'admin#visibility'
    
    post 'user/togglebadge/:badge_id' => 'admin#togglebadge'
    post 'user/role/:role' => 'admin#role'
    
    # Reporting #
    get 'reports/page' => 'report#page'
    get 'reports/:id' => 'report#view'
    get 'report/:id/new' => 'report#new'
    post 'report/:id' => 'report#create'
    post 'report/:id/:async' => 'report#create'
    
    post ':table/reindex' => 'admin#reindex'
    
    root 'admin#view'
  end
  
  constraints CanAccessJobs do
    mount Resque::Server.new, at: "/admin/resque"
  end
  
  # Filters #
  get 'filters' => 'feed#edit'
  patch 'filters' => 'feed#update'
  
  # Videos #
  get 'videos/page' => 'video#page'
  get 'videos' => 'video#list'
  
  get 'feed/page' => 'feed#page'
  get 'feed' => 'feed#view'
  
  namespace :embed do
    get 'twitter' => 'twitter#view'
    get ':id' => 'video#view'
  end
  get 'oembed' => 'embed/video#oembed'
  
  get 'download/:id' => 'video#download'
  
  post 'star/:id' => 'ajax#star'
  post 'report/:id' => 'ajax#report'
  
  get 'history/:id' => 'history#page'
  
  get 'view/:id' => 'video#view', constraints: { id: /([0-9]+).*/ }
  get 'ajax/view/:id' => 'video#go_next'
  
  get 'video/:id/edit' => 'video#edit'
  get 'video/:id/changes' => 'history#view'
  
  get 'upload' => 'video#upload'
  
  post 'like/:id(/:incr)' => 'ajax#upvote'
  post 'dislike/:id(/:incr)' => 'ajax#downvote'
  post 'video/togglealbum' => 'ajax#toggle_album'
  post 'video/feature' => 'ajax#toggle_feature'
  
  post 'video/:async' => 'video#create'
  post 'video' => 'video#create'
  patch 'video/:id/cover/:async' => 'video#update_cover'
  patch 'video/:id/cover' => 'video#update_cover'
  patch 'video/:id/:async' => 'video#video_update'
  patch 'video/:id' => 'video#video_update'
  patch 'video/:id' => 'video#update'
  delete 'video/:id' => 'admin#delete_video'
  
  # Users #
  get 'users/page' => 'artist#page'
  get 'users' => 'artist#list'
  
  get 'profile/:id' => 'artist#view', constraints: { id: /([0-9]+).*/ }
  get 'user/:id/hovercard' => 'artist#card'
  
  get 'user/:id/banner' => 'artist#banner'
  
  patch 'user/avatar/:async' => 'artist#setavatar'
  patch 'user/avatar' => 'artist#setavatar'
  patch 'user/banner/:async' => 'artist#setbanner'
  patch 'user/banner' => 'artist#setbanner'
  patch 'user/:id' => 'artist#update'
  
  post 'find/users' => 'search#autofill_artist'
  
  get 'cover/:id-small' => 'imgs#thumb'
  get 'cover/:id' => 'imgs#cover'
  get 'avatar/:id-small' => 'imgs#avatar', constraints: { id: /[0-9]+/ }
  get 'avatar/:id' => 'imgs#avatar', constraints: { id: /[0-9]+/ }
  get 'banner/:id' => 'imgs#banner'
  get 'stream/:id' => 'imgs#stream', constraints: { id: /.*/ }
  
  # Albums #
  get 'album/:id' => 'album#view'
  
  get 'albums/page' => 'album#page'
  get 'albums' => 'album#list'
  
  get 'albums/new' => 'album#new'
  get 'albums/:id/edit' => 'album#edit'
  
  post 'albums' => 'album#create'
  patch 'albums/:id/order' => 'album#update_ordering'
  patch 'albums/:id' => 'album#update'
  delete 'albums/:id' => 'album#delete'
  
  get 'albumitems' => 'album#items'
  post 'albumitems' => 'album#add_item'
  patch 'albumitems/:id' => 'album#arrange'
  delete 'albumitems/:id' => 'album#removeItem'
  
  # Tags #
  get 'tags' => 'genre#list'
  get 'tags/page' => 'genre#page'
  
  get 'tags/videos' => 'genre#videos'
  get 'tags/users' => 'genre#users'
  
  get 'tags/:name', to: 'genre#view', constraints: { name: /.*/ }
  
  patch 'tag/hide' => 'genre#hide'
  patch 'tag/spoiler' => 'genre#spoiler'
  patch 'tag/watch' => 'genre#watch'
  patch 'tags/:id' => 'genre#update'
  
  get 'find/tags' => 'genre#find'
  
  # Forums #
  get 'forum' => 'board#list'
  get 'forum/search' => 'thread#search'
  get 'forum/search/page' => 'thread#page_search'
  get 'forum/:id' => 'board#view'
  
  # Boards/Categories #
  get 'boards/page' => 'board#page'
  get 'boards/new' => 'board#new'
  post 'boards' => 'board#create'
  delete 'boards/:id' => 'board#delete'
  
  # Threads #
  get 'thread/:id' => 'thread#view', constraints: { id: /([0-9]+).*/ }
  
  get 'threads/:id/page' => 'thread#page_threads'
  get 'threads/new' => 'thread#new'
  post 'threads' => 'thread#create'
  patch 'threads/:id' => 'thread#update'
  
  post 'thread/pin' => 'ajax#toggle_pin'
  post 'thread/lock' => 'ajax#toggle_lock'
  post 'thread/move' => 'thread#move'
  post 'thread/subscribe' => 'ajax#toggle_subscribe'
  
  post 'comments' => 'thread#post_comment'
  patch 'comments/:id' => 'thread#edit_comment'
  delete 'comments/:id' => 'thread#remove_comment'
  
  post 'comments/like/:id(/:incr)' => 'ajax#like'
  get 'comments/:thread_id/:order/page' => 'thread#page'
  get 'find/comments' => 'thread#get_comment'
  
  # Private Messages #
  get 'messages' => 'pm#list'
  get 'messages/page' => 'pm#page_threads'
  get 'messages/tab' => 'pm#tab'
  get 'messages/:type' => 'pm#list'
  post 'messages' => 'pm#create'
  
  get 'message/:id' => 'pm#view'
  get 'message/new' => 'pm#new'
  patch 'message/markread' => 'pm#mark_read'
  delete 'message/:type/:id' => 'pm#delete_pm'
  
  # Notifications #
  get 'notifications' => 'thread#notifications'
  get 'ajax/notifications' => 'ajax#notifications'
  
  get 'review' => 'thread#mark_read'
  delete 'notifications/:id' => 'thread#delete_notification'
  
  namespace :api do
    # API #
    get 'videos' => 'video#find'
    get 'video/get/:id' => 'video#details'
    post 'video/set/:id' => 'video#update'
  end
  
  # Short link #
  get '/:id' => 'video#view', constraints: { id: /([0-9]+).*/ }
  
  # Home #
  get '/' => 'welcome#index'
  root 'welcome#index'
end

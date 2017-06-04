Rails.application.routes.draw do
  devise_for :users
  put 'users/prefs' => 'artist#update_prefs'
  
  get 'stars' => 'album#starred'
  get 'search' => 'search#index'
  get 'ajax/search' => 'search#page'
  
  get 'staff' => 'staff#index'
  
  get 'copyright' => 'staff#copyright'
  get 'fairuse' => 'staff#copyright'
  get 'policy' => 'staff#policy'
  get 'terms' => 'staff#policy'
  get 'badges' => 'badge#index'
  
  get 'ajax/donate' => 'ajax#donate'
  get 'donate' => 'staff#donate'
  get 'ajax/login' => 'ajax#login'
  
  # Admin Actions #
  get 'admin' => 'admin#view'
  get 'admin/report/view/:id' => 'admin#view_report'
  get 'admin/files' => 'admin#files'
  get 'admin/album/:id' => 'admin#album'
  get 'admin/video/:id' => 'admin#video'
  get 'admin/artist/:id' => 'admin#artist'
  get 'admin/tag/:id' => 'admin#tag'
  get 'admin/tags' => 'genre_admin#view'
  
  put 'admin/video/reprocess' => 'admin#reprocessVideo'
  put 'admin/video/resetthumb' => 'admin#extractThumbnail'
  put 'admin/video/merge' => 'admin#merge'
  put 'admin/video/metadata' => 'admin#populateVideo'
  put 'admin/transfer' => 'admin#transferItem'
  put 'admin/reindex/:table' => 'admin#reindex'
  
  get 'ajax/admin/files' => 'admin#morefiles'
  get 'ajax/admin/videos/hidden' => 'admin#page_hidden'
  get 'ajax/admin/videos/unprocessed' => 'admin#page_unprocessed'
  post 'ajax/admin/process/all' => 'admin#batch_preprocessVideos'
  post 'ajax/admin/verify' => 'admin#verify_integrity'
  post 'ajax/admin/requeue' => 'admin#rebuildQueue'
  post 'ajax/admin/hidden/drop' => 'admin#batch_dropVideos'
  post 'ajax/admin/reindex/:table' => 'admin#reindex'
  
  post 'ajax/video/hide' => 'admin#visibility'
  post 'ajax/user/togglebadge/:badge_id' => 'admin#togglebadge'
  post 'ajax/user/role/:role' => 'admin#role'
  
  post 'ajax/tagtype/update' => 'genre_admin#update'
  post 'ajax/tagtype/create' => 'genre_admin#create'
  post 'ajax/tagtype/delete/:id' => 'genre_admin#delete'
  get 'ajax/tagtype/new' => 'genre_admin#new'
  
  # Filters #
  get 'filters' => 'feed#edit'
  patch 'filters' => 'feed#update'
  get 'ajax/feed' => 'feed#page'
  
  # Videos #
  get 'videos' => 'video#list'
  get 'feed' => 'feed#view'
  get 'ajax/videos' => 'video#page'
  
  get 'view/:id' => 'video#view', constraints: { id: /([0-9]+).*/ }
  get 'upload' => 'video#upload'
  get 'video/edit/:id' => 'video#edit'
  patch 'ajax/video/edit' => 'video#video_update'
  patch 'ajax/video/edit/:async' => 'video#video_update'
  
  get 'video/:id/changes' => 'history#view'
  get 'ajax/history/:id' => 'history#page'
  
  get 'embed/:id' => 'embed#view'
  get 'oembed' => 'embed#oembed'
  get 'download/:id' => 'video#download'
  
  get 'ajax/view/:id' => 'video#go_next'
  post 'ajax/upload/:async' => 'video#create'
  post 'ajax/upload' => 'video#create'
  post 'ajax/like/:id(/:incr)' => 'ajax#upvote'
  post 'ajax/dislike/:id(/:incr)' => 'ajax#downvote'
  post 'ajax/video/togglealbum' => 'ajax#toggleAlbum'
  post 'ajax/video/feature' => 'ajax#toggleFeature'
  post 'ajax/star/:id' => 'ajax#star'
  post 'ajax/report/:id' => 'ajax#report'
  
  post 'ajax/create/video' => 'video#create'
  patch 'ajax/update/video/:async' => 'video#updateCover'
  patch 'ajax/update/video' => 'video#updateCover'
  post 'ajax/update/video' => 'video#update'
  post 'ajax/delete/video/:id' => 'admin#deleteVideo'
  
  # Reporting #
  get 'ajax/reporter/:id' => 'admin#reporter'
  post 'ajax/reporter/:id' => 'admin#report'
  
  post 'report/:id' => 'admin#report'
  post 'report/:id/:async' => 'admin#report'
  
  # Users #
  get 'users' => 'artist#list'
  get 'ajax/users' => 'artist#page'
  
  get 'profile/:id' => 'artist#view', constraints: { id: /([0-9]+).*/ }
  get 'ajax/artist/hovercard' => 'artist#card'
  get 'ajax/artist/update/banner/:id' => 'artist#banner'
  post 'ajax/artist/lookup' => 'search#autofillArtist'
  patch 'ajax/update/artist' => 'artist#update'
  patch 'ajax/avatar/upload/:async' => 'artist#setavatar'
  patch 'ajax/avatar/upload' => 'artist#setavatar'
  patch 'ajax/banner/upload/:id/:async' => 'artist#setbanner'
  patch 'ajax/banner/upload/:id' => 'artist#setbanner'
  
  get 'cover/:id-small' => 'imgs#thumb'
  get 'cover/:id' => 'imgs#cover'
  get 'avatar/:id-small' => 'imgs#avatar', constraints: { id: /[0-9]+/ }
  get 'avatar/:id' => 'imgs#avatar', constraints: { id: /[0-9]+/ }
  get 'banner/:id' => 'imgs#banner'
  get 'stream/:id' => 'imgs#stream', constraints: { id: /.*/ }
  
  # Albums #
  get 'album/:id' => 'album#view'
  get 'albums' => 'album#list'
  
  get 'ajax/albums/items' => 'album#items'
  get 'ajax/albums' => 'album#page'
  get 'ajax/album/create' => 'album#new'
  get 'ajax/album/update/:id' => 'album#edit'
  
  post 'ajax/album/feature' => 'ajax#toggleAlbumFeature'
  post 'ajax/create/album' => 'album#create'
  post 'ajax/update/album' => 'album#update'
  post 'ajax/delete/album/:id' => 'album#delete'
  patch 'ajax/edit/album/:id' => 'album#update_ordering'
  
  post 'ajax/create/albumitem' => 'album#addItem'
  post 'ajax/update/albumitem' => 'album#arrange'
  post 'ajax/delete/albumitem' => 'album#removeItem'
  
  # Stars #
  
  post 'ajax/update/star' => 'album#arrangeStar'
  post 'ajax/delete/star' => 'album#removeStar'
  
  # Tags #
  get 'tags' => 'genre#list'
  get 'ajax/genres' => 'genre#page'
  
  get 'tags/:name', to: 'genre#view', constraints: { name: /.*/ }
  patch 'ajax/tag/update/:id' => 'genre#update'
  post 'ajax/tag/hide' => 'genre#hide'
  post 'ajax/tag/spoiler' => 'genre#spoiler'
  post 'ajax/tag/watch' => 'genre#watch'
  get 'ajax/find/tags' => 'genre#find'
  get 'ajax/tags/videos' => 'genre#videos'
  get 'ajax/tags/users' => 'genre#users'
  
  # Forums #
  get 'forum' => 'board#list'
  get 'forum/search' => 'thread#search'
  get 'forum/:id' => 'board#view'
  get 'ajax/threads' => 'thread#page_threads'
  get '/ajax/forum/search' => 'thread#page_search'
  
  # Boards/Categories #
  get 'ajax/board/new' => 'board#new'
  post 'ajax/create/board' => 'board#create'
  post 'ajax/delete/board/:id' => 'board#delete'
  
  # Threads #
  get 'thread/:id' => 'thread#view', constraints: { id: /([0-9]+).*/ }
  
  get 'ajax/thread/new' => 'thread#new'
  post 'ajax/create/thread' => 'thread#create'
  post 'ajax/create/message' => 'pm#create'
  post 'ajax/update/thread' => 'thread#update'
  post 'ajax/thread/pin' => 'ajax#togglePin'
  post 'ajax/thread/lock' => 'ajax#toggleLock'
  post 'ajax/thread/move' => 'thread#move'
  post 'ajax/thread/subscribe' => 'ajax#toggleSubscribe'
  post 'ajax/comments/new' => 'thread#post_comment'
  post 'ajax/comments/delete/:id' => 'thread#remove_comment'
  post 'ajax/comments/edit' => 'thread#edit_comment'
  post 'ajax/comments/like/:id(/:incr)' => 'ajax#like'
  get 'ajax/comments/get' => 'thread#get_comment'
  get 'ajax/comments/:thread_id/:order' => 'thread#page'
  
  # Private Messages #
  get 'message/:id' => 'pm#view'
  get 'ajax/messages/tab' => 'pm#tab'
  get 'ajax/message/new' => 'pm#new'
  get 'messages' => 'pm#list'
  get 'messages/:type' => 'pm#list'
  get 'ajax/messages' => 'pm#page_threads'
  post 'ajax/message/markread' => 'pm#mark_read'
  post 'ajax/delete/message/:type' => 'pm#delete_pm'
  
  # Notifications #
  get 'notifications' => 'thread#notifications'
  get 'ajax/notifications' => 'ajax#notifications'
  post 'ajax/delete/notification' => 'thread#delete_notification'
  
  # API #
  get 'api/videos' => 'video#matching_videos'
  get 'api/video/get/:id' => 'video#video_details'
  post 'api/video/set/:id' => 'video#video_update'
  
  # Short link #
  get '/:id' => 'video#view', constraints: { id: /([0-9]+).*/ }
  
  # Home #
  get '/' => 'welcome#index'
  root 'welcome#index'
end

Rails.application.routes.draw do
  devise_for :users
  
  get 'stars' => 'album#starred'
  get 'search' => 'search#index'
  get 'ajax/search' => 'search#page'
  
  get 'staff' => 'staff#index'


  get 'copyright' => 'staff#copyright'
  get 'fairuse' => 'staff#copyright'
  get 'policy' => 'staff#policy'
  get 'terms' => 'staff#policy'
  
  get 'admin' => 'admin#view'
  get 'admin/report/view/:id' => 'admin#view_report'
  get 'admin/album/:id' => 'admin#album'
  get 'admin/video/:id' => 'admin#video'
  put 'admin/video/reprocess' => 'admin#reprocessVideo'
  put 'admin/video/resetthumb' => 'admin#extractThumbnail'
  get 'admin/artist/:id' => 'admin#artist'
  put 'admin/visibility' => 'admin#visibility'
  put 'admin/transfer' => 'admin#transferItem'
  post 'ajax/admin/process/all' => 'admin#batch_preprocessVideos'
  
  get 'view/:id' => 'video#view'
  get 'ajax/view/:id' => 'video#go_next'
  get 'embed/:id' => 'embed#view'
  get 'download/:id' => 'video#download'
  get 'upload' => 'video#upload'
  post 'ajax/upload/:async' => 'video#create'
  post 'ajax/upload' => 'video#create'
  get 'video/edit/:id' => 'video#edit'
  get 'videos' => 'video#list'
  get 'ajax/videos' => 'video#page'
  
  get 'profile/:id' => 'artist#view'
  get 'ajax/artist/hovercard' => 'artist#card'
  get 'ajax/artist/update/banner' => 'artist#banner'
  post 'ajax/artist/lookup' => 'search#autofillArtist'
  patch 'ajax/update/artist' => 'artist#update'
  patch 'ajax/avatar/upload/:async' => 'artist#setavatar'
  patch 'ajax/avatar/upload' => 'artist#setavatar'
  patch 'ajax/banner/upload/:async' => 'artist#setbanner'
  patch 'ajax/banner/upload' => 'artist#setbanner'
  
  get 'cover/:id-small' => 'imgs#thumb'
  get 'cover/:id' => 'imgs#cover'
  get 'avatar/:id' => 'imgs#avatar'
  get 'banner/:id' => 'imgs#banner'
  get 'stream/:id' => 'imgs#stream'
  
  get 'ajax/album/create' => 'album#new'
  get 'album/:id' => 'album#view'
  get 'albums' => 'album#list'
  get 'ajax/albums' => 'album#page'
  
  post 'ajax/create/album' => 'album#create'
  post 'ajax/update/album' => 'album#update'
  post 'ajax/delete/album/:id' => 'album#delete'
  
  get 'tags' => 'genre#list'
  get 'tags/:name', to: 'genre#view', constraints: { name: /.*/ }
  get 'ajax/find/tags' => 'genre#find'
  get 'ajax/genres' => 'genre#page'
  
  get 'ajax/reporter/:id' => 'admin#reporter'
  post 'ajax/reporter/:id' => 'admin#report'
  
  post 'ajax/like/:id(/:incr)' => 'ajax#upvote'
  post 'ajax/dislike/:id(/:incr)' => 'ajax#downvote'
  post 'ajax/video/togglealbum' => 'ajax#toggleAlbum'
  post 'ajax/star/:id' => 'ajax#star'
  post 'ajax/report/:id' => 'ajax#report'
  post 'report/:id' => 'admin#report'
  post 'report/:id/:async' => 'admin#report'
  
  post 'ajax/create/video' => 'video#create'
  patch 'ajax/update/video/cover/:async' => 'video#updateCover'
  patch 'ajax/update/video/cover' => 'video#updateCover'
  post 'ajax/update/video' => 'video#update'
  post 'ajax/delete/video/:id' => 'admin#deleteVideo'
  
  post 'ajax/create/albumitem' => 'album#addItem'
  post 'ajax/update/albumitem' => 'album#arrange'
  post 'ajax/delete/albumitem' => 'album#removeItem'
  
  post 'ajax/update/star' => 'album#arrangeStar'
  post 'ajax/delete/star' => 'album#removeStar'
  
  get 'notifications' => 'thread#notifications'
  
  get 'comments/:id' => 'thread#view'
  post 'ajax/comments/new' => 'thread#post_comment'
  post 'ajax/comments/delete/:id' => 'thread#remove_comment'
  post 'ajax/comments/edit' => 'thread#edit_comment'
  get 'ajax/comments/get' => 'thread#get_comment'
  get 'ajax/comments/:thread_id/:order' => 'thread#page'
  
  get '/' => 'welcome#index'
  root 'welcome#index'
end

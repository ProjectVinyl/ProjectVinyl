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
  get 'admin/album/:id' => 'admin#album'
  get 'admin/video/:id' => 'admin#video'
  put 'admin/video/reprocess' => 'admin#reprocessVideo'
  put 'admin/video/resetthumb' => 'admin#extractThumbnail'
  get 'admin/artist/:id' => 'admin#artist'
  put 'admin/visibility' => 'admin#visibility'
  put 'admin/transfer' => 'admin#transferItem'
  
  get 'view/:id' => 'video#view'
  get 'embed/:id' => 'embed#view'
  get 'download/:id' => 'video#download'
  get 'upload' => 'video#upload'
  post 'ajax/upload/:async' => 'video#create'
  post 'ajax/upload' => 'video#create'
  get 'video/edit/:id' => 'video#edit'
  get 'videos' => 'video#list'
  get 'ajax/videos' => 'video#page'
  
  get 'artist/create' => 'artist#new'
  get 'artist/:id' => 'artist#view'
  get 'artists' => 'artist#list'
  get 'ajax/artists' => 'artist#page'
  post 'ajax/artist/lookup' => 'search#autofillArtist'
  post 'ajax/create/artist' => 'artist#create'
  patch 'ajax/update/artist' => 'artist#update'
  post 'ajax/delete/artist/:id' => 'admin#deleteArtist'
  
  get 'cover/:id-small' => 'imgs#thumb'
  get 'cover/:id' => 'imgs#cover'
  get 'avatar/:id' => 'imgs#avatar'
  get 'stream/:id' => 'imgs#stream'
  
  get 'ajax/album/create' => 'album#new'
  get 'album/:id' => 'album#view'
  get 'albums' => 'album#list'
  get 'ajax/albums' => 'album#page'
  
  post 'ajax/create/album' => 'album#create'
  post 'ajax/update/album' => 'album#update'
  post 'ajax/delete/album/:id' => 'album#delete'
  
  get 'genre/:name' => 'genre#view'


  get 'genres' => 'genre#list'
  get 'ajax/genres' => 'genre#page'
  
  get 'ajax/reporter/:id' => 'ajax#reporter'
  
  post 'ajax/like/:id(/:incr)' => 'ajax#upvote'
  post 'ajax/dislike/:id(/:incr)' => 'ajax#downvote'
  post 'ajax/video/togglealbum' => 'ajax#toggleAlbum'
  post 'ajax/star/:id' => 'ajax#star'
  post 'ajax/report/:id' => 'ajax#report'
  
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
  
  get '/' => 'welcome#index'
  root 'welcome#index'
end

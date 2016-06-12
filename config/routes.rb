Rails.application.routes.draw do
  devise_for :users
  
  get 'stars' => 'album#starred'
  
  get 'search' => 'search#index'
  get 'ajax/search' => 'search#page'
  
  get 'staff' => 'staff#index'


  get 'admin' => 'admin#view'
  get 'admin/album/:id' => 'admin#album'
  get 'admin/video/:id' => 'admin#video'
  get 'admin/artist/:id' => 'admin#artist'
  put 'admin/visibility' => 'admin#visibility'
  put 'admin/transfer' => 'admin#transferItem'
  
  get 'view/:id' => 'video#view'
  get 'embed/:id' => 'embed#view'
  get 'download/:id' => 'video#download'
  get 'upload' => 'video#upload'
  post 'ajax/upload' => 'video#create'
  get 'videos' => 'video#list'
  get 'ajax/videos' => 'video#page'
  
  get 'artist/create' => 'artist#new'
  post 'ajax/artist/create' => 'artist#create'
  patch 'ajax/artist/edit' => 'artist#update'
  get 'artist/:id' => 'artist#view'
  get 'artists' => 'artist#list'
  get 'ajax/artists' => 'artist#page'
  
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
  post 'ajax/update/video' => 'video#update'
  
  post 'ajax/create/albumitem' => 'album#addItem'
  post 'ajax/update/albumitem' => 'album#arrange'
  post 'ajax/delete/albumitem' => 'album#removeItem'
  
  post 'ajax/update/star' => 'album#arrangeStar'
  post 'ajax/delete/star' => 'album#removeStar'
  
  get '/' => 'welcome#index'
  root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
  
  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end

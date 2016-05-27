Rails.application.routes.draw do
  get 'embed/view'
  get 'search' => 'search#index'
  get 'staff' => 'staff#index'


  get 'login' => 'login#index'
  
  get 'view/:id' => 'view#view'
  get 'embed/:id' => 'embed#view'
  get 'artist/:id' => 'artist#view'
  get 'album/:id' => 'album#view'
  get 'genre/:name' => 'genre#view'


  get 'download/:id' => 'imgs#download'
  
  get 'videos' => 'view#videos'
  get 'albums' => 'view#albums'
  get 'artists' => 'view#artists'
  get 'genres' => 'view#genres'
  
  get 'ajax/search' => 'search#page'
  get 'ajax/videos' => 'view#videos_json'
  get 'ajax/albums' => 'view#albums_json'
  get 'ajax/artists' => 'view#artists_json'
  get 'ajax/genres' => 'view#genres_json'
  get 'ajax/reporter/:id' => 'view#reporter'
  
  post 'ajax/like/:id(/:incr)' => 'view#upvote'
  post 'ajax/dislike/:id(/:incr)' => 'view#downvote'
  post 'ajax/report/:id' => 'view#report'
  
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

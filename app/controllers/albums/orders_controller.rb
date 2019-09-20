module Albums
  class OrdersController < BaseAlbumsController
    def update
      check_then :album_id do |album|
        album.set_ordering(params[:album][:sorting], params[:album][:direction])
        album.listing = params[:album][:privacy].to_i
        album.save

        redirect_to action: :show, controller: :albums, id: album.id
      end
    end
  end
end

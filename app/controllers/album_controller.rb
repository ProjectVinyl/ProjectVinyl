class AlbumController < ApplicationController
  def view
    if @album = Album.where(id: params[:id].split(/-/)[0]).first
      @items = @album.album_items.order(:index)
      @modificationsAllowed = session[:current_user_id] == @album.artist.id
    end
  end
  
  def arrange
    if user_signed_in?
      if item = AlbumItem.where(id: params[:id]).first
        if item.album.artist_id == current_user.artist_id
          item.move(params[:index])
          render status: 200, nothing: true
          return
        end
      end
    end
    render status: 401, nothing: true
  end
  
  def arrangeStar
    if user_signed_in?
      if item = current_user.stars.where(id: params[:id]).first
        item.move(params[:index].to_i)
        render status: 200, nothing: true
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def removeItem
    if user_signed_in?
      if item = AlbumItem.where(id: params[:id]).first
        if item.album.artist_id == current_user.artist_id
          item.removeSelf()
          render status: 200, nothing: true
          return
        end
      end
    end
    render status: 401, nothing: true
  end
  
  def removeStar
    if user_signed_in?
      if item = current_user.stars.where(id: params[:id]).first
        item.removeSelf()
        render status: 200, nothing: true
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def addItem
    if user_signed_in?
      if album = Album.where(id: params[:id]).first
        if album.artist_id == current_user.artist_id
          if video = Video.where(id: params[:videoId]).first
            album.addItem(video)
            render status: 200, nothing: true
            return
          end
        end
      end
    end
    render status: 401, nothing: true
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(Album.order(:created_at), @page, 50, true)
    render template: '/view/listing', locals: {type_id: 1, type: 'albums', type_label: 'Album', items: @results}
  end
  
  def page
    @page = params[:page].to_i
    @artist = params[:artist]
    if @artist.nil?
      @results = Pagination.paginate(Album.order(:created_at), @page, 50, true)
    else
      @results = Pagination.paginate(Artist.find(@artist.to_i).albums.order(:created_at), @page, 8, true)
    end
    render json: {
      content: render_to_string(partial: '/layouts/album_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def starred
    if user_signed_in?
      @artist = Artist.where(id: current_user.artist_id).first
      @items = current_user.stars.order(:index)
    end
  end
end

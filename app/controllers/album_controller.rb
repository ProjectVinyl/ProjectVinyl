class AlbumController < ApplicationController
  def view
    if @album = Album.where(id: params[:id].split(/-/)[0]).first
      if @album.owner_type != 'Artist'
        render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
        return
      end
      @artist = @album.owner
      @items = @album.album_items.includes(:artist).order(:index)
      @modificationsAllowed = user_signed_in? && @album.ownedBy(current_user)
    end
  end
  
  def new
    @album = Album.new
    if params[:initial]
      @initial = params[:initial]
    end
    render partial: 'new'
  end
  
  def create
    if user_signed_in?
      if current_user.artist_id
        album = params[:album]
        initial = album[:initial]
        album = Artist.find(current_user.artist_id).albums.create(title: ApplicationHelper.demotify(album[:title]), description: ApplicationHelper.demotify(album[:description]))
        if initial
          if initial = Video.where(id: initial).first
            album.addItem(initial)
            redirect_to action: 'view', controller: "video", id: initial.id
            return
          end
        end
        redirect_to action: 'view', id: album.id
        return
      end
    end
    redirect_to action: "index", controller: "welcome"
  end
  
  def update
    if user_signed_in? && album = Album.where(id: params[:id]).first
      if album.ownedBy(current_user)
        value = ApplicationHelper.demotify(params[:value])
        if params[:field] == 'description'
          album.description = value
          album.save
        elsif params[:field] == 'title'
          album.title = value
          album.save
        end
        render status: 200, nothing: true
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def delete
    if user_signed_in? && album = Album.where(id: params[:id]).first
      if album.owner_type == 'Artist' && (current_user.is_admin || album.owner.id == current_user.artist_id)
        album.destroy
        render json: {
          ref: url_for(action: "view", controller: "artist", id: album.owner.id)
        }
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def arrange
    if user_signed_in?
      if item = AlbumItem.where(id: params[:id]).first
        if item.album.ownedBy(current_user)
          item.move(params[:index].to_i)
          render status: 200, nothing: true
          return
        end
      end
    end
    render status: 401, nothing: true
  end
  
  def arrangeStar
    if user_signed_in?
      if item = current_user.album_items.where(id: params[:id]).first
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
        if item.album.ownedBy(current_user)
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
      if item = current_user.album_items.where(id: params[:id]).first
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
        if album.ownedBy(current_user)
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
    @results = Pagination.paginate(Album.where(owner_type: 'Artist').order(:created_at), @page, 50, true)
    render template: '/view/listing', locals: {type_id: 1, type: 'albums', type_label: 'Album', items: @results}
  end
  
  def page
    @page = params[:page].to_i
    @artist = params[:artist]
    if @artist.nil?
      @results = Pagination.paginate(Album.where(owner_type: 'Artist').order(:created_at), @page, 50, true)
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
      @items = current_user.album_items.order(:index)
      @album = current_user.stars
      @modificationsAllowed = true
    end
    render template: '/album/view'
  end
end

class AlbumController < ApplicationController
  def show
    if !(@album = Album.where(id: params[:id].split(/-/)[0]).first)
      return render_error(
        title: 'Nothing to see here!',
        description: 'This album appears to have been  moved or deleted.'
      )
    end
    
    if @album.hidden
      return render_access_denied
    end
    
    if @album.listing == 2 && !@album.owned_by(current_user)
      return render_error(
        title: 'Album Hidden',
        description: "This album is private."
      )
    end
    
    @user = @album.user
    @records = @album.ordered(@album.album_items.includes(:direct_user))
    @items = Pagination.paginate(@records, 0, 50, false)
    @modifications_allowed = user_signed_in? && @album.owned_by(current_user)
    
    @metadata = {
      type: "album",
      title: @album.title,
      description: @album.description,
      tags: [],
      url: "#{url_for(action: :show, controller: :album, id: @album.id, only_path: false)}-#{@album.safe_title}",
      embed_url: url_for({
        action: "view",
        controller: "embed/video",
        id: @items.records.first.video_id,
        list: @album.id,
        index: 0,
        only_path: false
      }),
      cover: Video.thumb_for(@items.records.first, current_user),
      oembed: {
        list: @album.id,
        index: 0
      }
    }
  end
  
  def starred
    if user_signed_in?
      @user = current_user
      @album = current_user.stars
      
      @records = @album.ordered(@album.album_items.includes(:direct_user))
      @items = Pagination.paginate(@records, 0, 50, false)
      @modifications_allowed = true
    end
    
    render template: 'album/view'
  end
  
  def new
    @album = Album.new
    @initial = params[:initial] if params[:initial]
    render partial: 'new'
  end
  
  def create
    if !user_signed_in?
      flash[:error] = "You need to sign in to do that."
      redirect_to action: "index", controller: "welcome"
    end
    
    album = current_user.albums.create
    album.set_description(album[:description])
    album.set_title(params[:album][:title])
    
    initial = params[:album][:initial]
    if initial && (initial = Video.where(id: initial).first)
      album.add_item(initial)
      return redirect_to action: 'view', controller: "video", id: initial.id
    end
    
    redirect_to action: 'view', id: album.id
  end
  
  def edit
    check_then :id do |album|
      render partial: 'edit'
    end
  end
  
  def order
    check_then :album_id do |album|
      album.set_ordering(params[:album][:sorting], params[:album][:direction])
      album.listing = params[:album][:privacy].to_i
      album.save
      
      redirect_to action: 'view', id: album.id
    end
  end
  
  def update
    check_then :id do |album|
      if params[:field] == 'description'
        album.set_description(params[:value])
        album.save
      elsif params[:field] == 'title'
        album.set_title(params[:value])
      end
      head :ok
    end
  end
  
  def destroy
    check_then :id do |album|
      if album.hidden
        return head 401
      end
      
      album.destroy
      redirect_to url_for(action: "view", controller: "artist", id: album.user_id)
    end
  end
  
  def index
    @records = Album.where(hidden: false, listing: 0).order(:created_at)
    render_listing @records, params[:page].to_i, 50, true, {
      table: 'albums', label: 'Album'
    }
  end
  
  def page
    if !params[:user]
      @page_size = 50
      @records = Album.where(hidden: false, listing: 0)
    else
      @page_size = 8
      if params[:user].to_i == current_user.id
        @records = current_user.albums
      else
        if !(@user = User.where(id: params[:user]).first)
          return head :not_found
        end
        @records = @user.albums.where(listing: 0)
      end
    end
    
    render_pagination 'album/thumb_h', @records.order(:created_at), params[:page].to_i, @page_size, true
  end
  
  private
  def check_then(id)
    if !user_signed_in?
      return head 401
    end
    
    if !(album = Album.where(id: params[id]).first)
      return head :not_found
    end
    
    if !album.owned_by(current_user)
      return head 401
    end
    
    yield(album)
  end
end

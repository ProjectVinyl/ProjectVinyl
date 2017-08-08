class AlbumController < ApplicationController
  def view
    if !(@album = Album.where(id: params[:id].split(/-/)[0]).first)
      return render 'layouts/error', locals: {
        title: 'Nothing to see here!',
        description: 'This album appears to have been  moved or deleted.'
      }
    end
    
    if @album.hidden
      return render 'layouts/error', locals: {
        title: 'Access Denied',
        description: "You can't do that right now."
      }
    end
    
    if @album.listing == 2 && !@album.owned_by(current_user)
      return render 'layouts/error', locals: {
        title: 'Album Hidden',
        description: "This album is private."
      }
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
      url: "#{url_for(action: "view", controller: "album", id: @album.id, only_path: false)}-#{@album.safe_title}",
      embed_url: url_for(action: "view", controller: "embed/video", id: @items.records.first.video_id, list: @album.id, index: 0, only_path: false),
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
  
  def edit
    if !user_signed_in?
      return head 401
    end
    
    if !(@album = Album.where(id: params[:id]).first)
      return head 404
    end
    
    if @album.owned_by(current_user)
      return head 401
    end
    
    return render partial: 'edit' 
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
  
  def update_ordering
    if !user_signed_in?
      return head 401
    end
    
    if !(@album = Album.where(id: params[:id]).first)
      return head 404
    end
    
    if !@album.owned_by(current_user)
      return head 401
    end
    
    @album.set_ordering(params[:album][:sorting], params[:album][:direction])
    @album.listing = params[:album][:privacy].to_i
    @album.save
    return redirect_to action: 'view', id: @album.id
  end
  
  def update
    if !user_signed_in?
      return head 401
    end
    
    if !(album = Album.where(id: params[:id]).first)
      return head 404
    end
    
    if !album.owned_by(current_user)
      return head 401
    end
    
    value = ApplicationHelper.demotify(params[:value])
    if params[:field] == 'description'
      album.set_description(value)
      album.save
    elsif params[:field] == 'title'
      album.set_title(value)
    end
    return head 200
  end
  
  def destroy
    if !user_signed_in?
      return head 401
    end
    
    if !(album = Album.where(id: params[:id]).first)
      return head 404
    end
    
    if album.hidden || !album.owned_by(current_user)
      return head 401
    end
    
    album.destroy
    redirect_to url_for(action: "view", controller: "artist", id: album.user_id)
  end
  
  def index
    @records = Album.where('hidden = false AND listing = 0').order(:created_at)
    render template: 'pagination/listing', locals: {
      type_id: 1,
      type: 'albums',
      type_label: 'Album',
      items: Pagination.paginate(@records, params[:page].to_i, 50, true)
    }
  end
  
  def page
    @page = params[:page].to_i
    @user = params[:user]
    
    if @artist.nil?
      @results = Pagination.paginate(Album.where('hidden = false AND listing = 0').order(:created_at), @page, 50, true)
    else
      
      @results = User.find(@user.to_i).albums
      
      if @user.to_i != current_user.id
        @results = @results.where('listing = 0')
      end
      
      @results = Pagination.paginate(@results.order(:created_at), @page, 8, true)
    end
    
    render_pagination 'album/thumb_h', @results
  end
end

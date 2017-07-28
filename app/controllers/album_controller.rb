class AlbumController < ApplicationController
  def view
    if !(@album = Album.where(id: params[:id].split(/-/)[0]).first)
      return render '/layouts/error', locals: { title: 'Nothing to see here!', description: 'This album appears to have been  moved or deleted.' }
    end
    if @album.hidden
      return render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
    end
    if @album.listing == 2 && !@album.owned_by(current_user)
      return render 'layouts/error', locals: { title: 'Album Hidden', description: "This album is private." }
    end
    
    @user = @album.user
    @items = Pagination.paginate(@album.ordered(@album.album_items.includes(:direct_user)), 0, 50, false)
    @modifications_allowed = user_signed_in? && @album.owned_by(current_user)
    
    @metadata = {
      type: "album",
      title: @album.title,
      description: @album.description,
      tags: [],
      url: "#{url_for(action: "view", controller: "album", id: @album.id, only_path: false)}-#{@album.safe_title}",
      embed_url: url_for(action: "view", controller: "embed", only_path: false, id: @items.records.first.video_id, list: @album.id, index: 0),
      cover: Video.thumb_for(@items.records.first, current_user),
      oembed: { list: @album.id, index: 0 }
    }
  end
  
  def starred
    if user_signed_in?
      @user = current_user
      @album = current_user.stars
      @items = current_user.album_items.order(:index)
      @items = Pagination.paginate(@album.ordered(@album.album_items.includes(:direct_user)), 0, 50, false)
      @modifications_allowed = true
    end
    render template: '/album/view'
  end
  
  def new
    @album = Album.new
    @initial = params[:initial] if params[:initial]
    render partial: 'new'
  end
  
  def edit
    if user_signed_in? && @album = Album.where(id: params[:id]).first
      return render partial: 'edit' if @album.owned_by(current_user)
    end
    head 401
  end
  
  def create
    if user_signed_in?
      album = params[:album]
      initial = album[:initial]
      album = current_user.albums.create
      album.set_description(album[:description])
      album.set_title(params[:album][:title])
      if initial
        if initial = Video.where(id: initial).first
          album.add_item(initial)
          return redirect_to action: 'view', controller: "video", id: initial.id
        end
      end
      redirect_to action: 'view', id: album.id
      return
    end
    redirect_to action: "index", controller: "welcome"
  end
  
  def update_ordering
    if user_signed_in? && @album = Album.where(id: params[:id]).first
      if @album.owned_by(current_user)
        @album.set_ordering(params[:album][:sorting], params[:album][:direction])
        @album.listing = params[:album][:privacy].to_i
        @album.save
        return redirect_to action: 'view', id: @album.id
      end
    end
    head 401
  end
  
  def update
    if user_signed_in? && album = Album.where(id: params[:id]).first
      if album.owned_by(current_user)
        value = ApplicationHelper.demotify(params[:value])
        if params[:field] == 'description'
          album.set_description(value)
          album.save
        elsif params[:field] == 'title'
          album.set_title(value)
        end
        return head 200
      end
    end
    head 401
  end
  
  def delete
    if user_signed_in? && album = Album.where(id: params[:id]).first
      if !album.hidden && (current_user.is_staff? || album.user_id == current_user.id)
        album.destroy
        return redirect_to url_for(action: "view", controller: "artist", id: album.user_id)
      end
    end
    head 401
  end
  
  def arrange
    if user_signed_in?
      if item = AlbumItem.where(id: params[:id]).first
        if item.album.owned_by(current_user)
          item.move(params[:index].to_i)
          return head 200
        end
      end
    end
    head 401
  end
  
  def remove_item
    if user_signed_in?
      if item = AlbumItem.where(id: params[:id]).first
        if item.album.owned_by(current_user)
          item.remove_self
          return head 200
        end
      end
    end
    head 401
  end
  
  def add_item
    if user_signed_in?
      if album = Album.where(id: params[:id]).first
        if album.owned_by(current_user)
          if video = Video.where(id: params[:videoId]).first
            album.add_item(video)
            return head 200
          end
        end
      end
    end
    head 401
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(Album.where('hidden = false AND listing = 0').order(:created_at), @page, 50, true)
    render template: '/view/listing', locals: { type_id: 1, type: 'albums', type_label: 'Album', items: @results }
  end
  
  def page
    @page = params[:page].to_i
    @user = params[:user]
    if @artist.nil?
      @results = Pagination.paginate(Album.where('hidden = false AND listing = 0').order(:created_at), @page, 50, true)
    else
      @results = User.find(@user.to_i).albums
      @results = @results.where('listing = 0') if @user.to_i != current_user.id
      @results = Pagination.paginate(@results.order(:created_at), @page, 8, true)
    end
    render json: {
      content: render_to_string(partial: '/layouts/album_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def items
    if @album = Album.where(id: params[:id]).first
      @page = params[:page].to_i
      @items = Pagination.paginate(@album.ordered(@album.album_items.includes(:direct_user)), @page, 50, false)
      @modifications_allowed = user_signed_in? && @album.owned_by(current_user)
      render json: {
        content: render_to_string(partial: '/album/item', collection: @items.records),
        pages: @items.pages,
        page: @items.page
      }
    end
  end
end

class AlbumsController < ApplicationController
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
      type: :album,
      title: @album.title,
      description: @album.description,
      tags: [],
      url: "#{url_for(action: :show, id: @album.id, only_path: false)}-#{@album.safe_title}",
      embed_url: url_for({
        action: :view,
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
    check_and do
      @user = current_user
      @album = current_user.stars
      
      @records = @album.ordered(@album.album_items.includes(:direct_user))
      @items = Pagination.paginate(@records, 0, 50, false)
      @modifications_allowed = true
      
      render template: 'albums/show'
    end
  end
  
  def new
    @album = Album.new
    @initial = params[:initial] if params[:initial]
    render partial: 'new'
  end
  
  def create
    check_and do
      album = current_user.albums.create
      album.set_description(album[:description])
      album.set_title(params[:album][:title])
      
      initial = params[:album][:initial]
      if initial && (initial = Video.where(id: initial).first)
        album.add_item(initial)
        return redirect_to action: :view, controller: :video, id: initial.id
      end
      
      redirect_to action: :show, id: album.id
    end
  end
  
  def edit
    check_then :id do |album|
      @album = album
      @listing = @album.hidden ? 2 : @album.listing
      @sorting = !@album.ordering || @album.ordering < 1 || @album.ordering > 3 ? 0 : @album.ordering
      @ordering = @album.reverse_ordering ? 0 : 1
      
      render partial: 'edit'
    end
  end
  
  def order
    check_then :album_id do |album|
      album.set_ordering(params[:album][:sorting], params[:album][:direction])
      album.listing = params[:album][:privacy].to_i
      album.save
      
      redirect_to action: :show, id: album.id
    end
  end
  
  def update
    check_then :id do |album|
      if params[:field] == 'description'
        album.set_description(params[:value])
				render json: { content: album.html_description }
      elsif params[:field] == 'title'
        album.set_title(params[:value])
				render json: { content: album.title }
      end
			album.save
    end
  end
  
  def destroy
    check_then :id do |album|
      if album.hidden
        return head :unauthorized
      end
      
      album.destroy
      redirect_to action: :view, controller: :user, id: album.user_id
    end
  end
  
  def index
    @records = Album.where(hidden: false, listing: 0).order(:created_at)
    render_listing_total @records, params[:page].to_i, 50, true, {
      table: 'albums', label: 'Album'
    }
  end
  
  private
  def check_and
    if !user_signed_in?
      flash[:error] = "You need to sign in to do that."
      return redirect_to action: :index, controller: :welcome
    end
    
    yield
  end
  
  def check_then(id)
    if !user_signed_in?
      return head :unauthorized
    end
    
    if !(album = Album.where(id: params[id]).first)
      return head :not_found
    end
    
    if !album.owned_by(current_user)
      return head :unauthorized
    end
    
    yield(album)
  end
end

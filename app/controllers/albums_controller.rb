class AlbumsController < Albums::BaseAlbumsController
  include Searchable
  
  configure_ordering [:title, :created_at]

  def show
    if !(@album = Album.where(id: params[:id].split(/-/)[0]).first)
      return render_error(
        title: 'Nothing to see here!',
        description: 'This album appears to have been  moved or deleted.'
      )
    end

    if (user_signed_in? && @album.id == current_user.star_id)
      return redirect_to action: :starred
    end
    
    if @album.hidden
      return render_access_denied
    end

    if !@album.visible_to?(current_user)
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
      og: {
        type: 'music.album'
      },
      type: :album,
      title: @album.title,
      description: @album.description,
      tags: [],
      url: "#{url_for(action: :show, id: @album.id, only_path: false)}-#{@album.safe_title}",
      embed_url: url_for({
        action: :show,
        controller: 'embed/videos',
        id: @items.count > 0 ? @items.records.first.video_id : 0,
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

  def new
    @album = Album.new
    @initial = Video.where(id: params[:initial]).first if params[:initial]
    render partial: 'new'
  end

  def create
    check_and do
      album = current_user.albums.create
      album.description = params[:album][:description]
      album.set_title(params[:album][:title])

      if params[:include_initial]
        initial = params[:album][:initial]
        if initial && (initial = Video.where(id: initial).first)
          album.add_item(initial)
          return redirect_to action: :show, controller: :video, id: initial.id
        end
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

  def update
    check_then :id do |album|
      if params[:field] == 'description'
        album.description = params[:value]
				render json: { content: BbcodeHelper.emotify(album.description) }
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
      redirect_to action: :show, controller: :users, id: album.user_id
    end
  end
  
  def index
    read_search_params params

    @records = Album.listed
    if filtered?
      @records = @records.where('LOWER(title) LIKE ?', @query.downcase.gsub(/\*/, '%'))
    end

    render_listing_total @records.order(:created_at), params[:page].to_i, 50, !@ascending, {
      template: 'pagination/search', table: 'albums', label: 'Album'
    }
  end
end

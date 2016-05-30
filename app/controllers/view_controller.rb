class ViewController < ApplicationController
  def view
    if @video = Video.where(id: params[:id].split(/-/)[0]).first
      @artist = @video.artist
      @queue = @artist.videos.where.not(id: @video.id).limit(5).order("RAND()")
      @modificationsAllowed = user_signed_in? && !current_user.artist_id.nil? && current_user.artist_id == @artist.id
    end
  end
  
  def videos
    @page = params[:page].to_i
    @results = Pagination.paginate(Video.order(:created_at), @page, 50, true)
    render template: '/view/listing', locals: {type_id: 0, type: 'videos', type_label: 'Song', items: @results}
  end
  
  def albums
    @page = params[:page].to_i
    @results = Pagination.paginate(Album.order(:created_at), @page, 50, true)
    render template: '/view/listing', locals: {type_id: 1, type: 'albums', type_label: 'Album', items: @results}
  end
  
  def artists
    @page = params[:page].to_i
    @results = Pagination.paginate(Artist.order(:created_at), @page, 50, true)
    render template: '/view/listing', locals: {type_id: 2, type: 'artists', type_label: 'Artist', items: @results}
  end
  
  def genres
    @page = params[:page].to_i
    @results = Pagination.paginate(Genre.order(:name), @page, 50, false)
    render template: '/view/listing', locals: {type_id: 3, type: 'genres', type_label: 'Genre', items: @results}
  end
  
  def videos_json
    @page = params[:page].to_i
    @artist = params[:artist]
    if @artist.nil?
      @results = Pagination.paginate(Video.order(:created_at), @page, 50, true)
    else
      @results = Pagination.paginate(Artist.find(@artist.to_i).videos.order(:created_at), @page, 8, true)
    end
    render json: {
      content: render_to_string(partial: '/layouts/video_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def albums_json
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
  
  def artists_json
    @page = params[:page].to_i
    @results = Pagination.paginate(Artist.order(:created_at), @page, 50, true)
    render json: {
      content: render_to_string(partial: '/layouts/artist_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def genres_json
    @page = params[:page].to_i
    @results = Pagination.paginate(Genre.order(:name), @page, 50, false)
    render json: {
      content: render_to_string(partial: '/layouts/genre_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
end

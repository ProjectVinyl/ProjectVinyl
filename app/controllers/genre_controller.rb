class GenreController < ApplicationController
  def view
    if @genre = Genre.where('safe_name = ?', ApplicationHelper.url_safe(params[:name])).first
      @totalVideos = @genre.videos.length
      @totalArtists = @genre.artists.length
      @videos = @genre.videos.where(hidden: false).order(:created_at).reverse_order.limit(16)
      @artists = @genre.artists.order(:updated_at).reverse_order.limit(16)
    end
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(Genre.order(:name), @page, 50, false)
    render template: '/view/listing', locals: {type_id: 3, type: 'genres', type_label: 'Genre', items: @results}
  end
  
  def page
    @page = params[:page].to_i
    @results = Pagination.paginate(Genre.order(:name), @page, 50, false)
    render json: {
      content: render_to_string(partial: '/layouts/genre_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
end

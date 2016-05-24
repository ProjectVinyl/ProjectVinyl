class SearchController < ApplicationController
  def index
    @query = params[:query]
    @page = params[:page].to_i
    @type_label = params[:type]
    @type = @type_label.to_i
    @ascending = params[:order] == '1'
    @orderby = params[:orderby].to_i
    @results = []
    if @type == 1
      @results = Album.where('title LIKE ?', "%#{@query}%")
      @type_label= 'Album'
    elsif @type == 2
      @results = Artist.where('name LIKE ?', "%#{@query}%")
      @type_label = 'Artist'
    elsif @type == 3
      @results = Genre.where('name LIKE ?', "%#{@query}%")
      @type_label = 'Genre'
    else
      @results = Video.where('title LIKE ?', "%#{@query}%")
      @type_label = 'Song'
    end
    @results = Pagination.paginate(@results, @page, 45, !@ascending)
  end
  
  def page
    @query = params[:query]
    @page = params[:page].to_i
    @type = params[:type].to_i
    @ascending = params[:order] == '1'
    @orderby = params[:orderby].to_i
    @results = []
    if params[:query]
      if @type == 1
        @results = Pagination.paginate(Album.where('title LIKE ?', "%#{@query}%"), @page, 20, !@ascending)
        #render partial: 'layouts/artist_thumb_h', collection: @results.records
        render json: {
          content: render_to_string(partial: '/layouts/artist_thumb_h.html.erb', collection: @results.records),
          pages: @results.pages,
          page: @results.page
        }
      elsif @type == 2
        @results = Pagination.paginate(Artist.where('name LIKE ?', "%#{@query}%"), @page, 20, !@ascending)
        #render partial: 'layouts/album_thumb_h', collection: @results.records
        render json: {
          content: render_to_string(partial: '/layouts/album_thumb_h.html.erb', collection: @results.records),
          pages: @results.pages,
          page: @results.page
        }
      elsif @type == 3
        @results = Pagination.paginate(Genre.where('name LIKE ?', "%#{@query}%"), @page, 20, !@ascending)
        render json: {
          content: render_to_string(partial: '/layouts/genre_thumb_h.html.erb', collection: @results.records),
          pages: @results.pages,
          page: @results.page
        }
      else
        @results = Pagination.paginate(Video.where('title LIKE ?', "%#{@query}%"), @page, 20, !@ascending)
        render json: {
          content: render_to_string(partial: '/layouts/video_thumb_h.html.erb', collection: @results.records),
          pages: @results.pages,
          page: @results.page
        }
      end
    end
  end
end

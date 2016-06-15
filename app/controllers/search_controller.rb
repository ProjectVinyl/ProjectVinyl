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
    @results = Pagination.paginate(orderBy(@results, @type, @orderby), @page, 20, !@ascending)
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
        @results = Pagination.paginate(orderBy(Album.where('title LIKE ?', "%#{@query}%"), @type, @orderby), @page, 20, !@ascending)
        render json: {
          content: render_to_string(partial: '/layouts/artist_thumb_h.html.erb', collection: @results.records),
          pages: @results.pages,
          page: @results.page
        }
      elsif @type == 2
        @results = Pagination.paginate(orderBy(Artist.where('name LIKE ?', "%#{@query}%"), @type, @orderby), @page, 20, !@ascending)
        render json: {
          content: render_to_string(partial: '/layouts/album_thumb_h.html.erb', collection: @results.records),
          pages: @results.pages,
          page: @results.page
        }
      elsif @type == 3
        @results = Pagination.paginate(orderBy(Genre.where('name LIKE ?', "%#{@query}%"), @type, @orderby), @page, 20, !@ascending)
        render json: {
          content: render_to_string(partial: '/layouts/genre_thumb_h.html.erb', collection: @results.records),
          pages: @results.pages,
          page: @results.page
        }
      else
        @results = Pagination.paginate(orderBy(Video.where('title LIKE ?', "%#{@query}%"), @type, @orderby), @page, 20, !@ascending)
        render json: {
          content: render_to_string(partial: '/layouts/video_thumb_h.html.erb', collection: @results.records),
          pages: @results.pages,
          page: @results.page
        }
      end
    end
  end
  
  def autofillArtist
    @query = params[:query]
    if !@query || @query == ''
      render json: {
        content: [],
        match: 0
      }
    else
      render json: {
        content: Artist.where('name LIKE ?', "%#{@query}%").uniq.limit(8).pluck(:id, :name),
        match: 1
      }
    end
  end
  
  def orderBy(records, type, ordering)
    if type == 0
      if ordering == 1
        return records.order(:created_at, :updated_at)
      end
      if ordering == 2
        return records.order(:score, :created_at, :updated_at)
      end
      if ordering == 3
        return records.order(:length, :created_at, :updated_at)
      end
    end
    return records.order(:created_at)
  end
end

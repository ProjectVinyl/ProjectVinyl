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
      @results = TagSelector.new(@query).userQuery(@page, 20).order(session, @orderby, @ascending).exec()
      @type_label = 'User'
      return
    elsif @type == 3
      @results = Tag.includes(:videos, :tag_type).where('name LIKE ?', "%#{@query}%")
      @type_label = 'Tag'
    else
      @results = TagSelector.new(@query).videoQuery(@page, 20).order(session, @orderby, @ascending).exec()
      @type_label = 'Song'
      return
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
          content: render_to_string(partial: '/layouts/album_thumb_h.html.erb', collection: @results.records),
          pages: @results.pages,
          page: @results.page
        }
      elsif @type == 2
        @results = TagSelector.new(@query).userQuery(@page, 20).order(session, @orderby, @ascending).exec()
        render json: {
          content: render_to_string(partial: '/layouts/artist_thumb_h.html.erb', collection: @results.records),
          pages: @results.pages,
          page: @results.page
        }
      elsif @type == 3
        @results = Pagination.paginate(orderBy(Tag.includes(:videos, :tag_type).where('name LIKE ?', "%#{@query}%"), @type, @orderby), @page, 20, !@ascending)
        render json: {
          content: render_to_string(partial: '/layouts/genre_thumb_h.html.erb', collection: @results.records),
          pages: @results.pages,
          page: @results.page
        }
      else
        @results = TagSelector.new(@query).videoQuery(@page, 20).order(session, @orderby, @ascending).exec()
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
        content: User.where('username LIKE ?', "%#{@query}%").uniq.limit(8).pluck(:id, :name),
        match: 1
      }
    end
  end
  
  def orderBy(records, type, ordering)
    if type == 0
      if ordering == 1
        return records.order(:created_at, :updated_at)
      elsif ordering == 2
        return records.order(:score, :created_at, :updated_at)
      elsif ordering == 3
        return records.order(:length, :created_at, :updated_at)
      end
    elsif type == 3
      return records.order(:name)
    end
    return records.order(:created_at)
  end
end

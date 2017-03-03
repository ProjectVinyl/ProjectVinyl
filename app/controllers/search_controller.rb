require 'projectvinyl/elasticsearch/elastic_selector'

class SearchController < ApplicationController
  def index
    @type_label = params[:type]
    @type = @type_label.to_i
    if @type == 2 || @type == 0
      @title_query = params[:query] || ""
      @tag_query = params[:tagquery] || ""
      @query = ""
      if @title_query.length > 0
        @query << "title:" + @title_query
      end
      if @tag_query.length > 0 && @query.length > 0
        @query << ","
      end
      @query << @tag_query
      if ApplicationHelper.valid_string?(@tag_query)
        @tag = Tag.includes(:alias).where('name = ? OR short_name = ?', @tag_query, @tag_query).first
        if @tag && @tag.alias_id
          @tag = @tag.alias
        end
      end
    else
      @query = @title_query = params[:query] || ""
    end
    @page = params[:page].to_i
    
    @ascending = params[:order] == '1'
    @orderby = params[:orderby].to_i
    @results = []
    if @type == 1
      @results = Album.where('title LIKE ?', "%#{@query}%")
      @type_label= 'Album'
    elsif @type == 2
      begin
        @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).query(@page, 20).users.order(session, @orderby, @ascending).exec()
      rescue ProjectVinyl::Search::LexerError => e
        @derpy = e
      rescue Exception => e
        @ditzy = e
      end
      @type_label = 'User'
      return
    elsif @type == 3
      @results = Tag.includes(:videos, :tag_type).where('name LIKE ?', "%#{@query}%")
      @type_label = 'Tag'
    else
      begin
        if params[:quick]
          @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).query(0, 1).videos.order_by('v.id').offset(-1).exec().records()
          if @results.first
            return redirect_to action: 'view', controller: 'embed', id: @results.first.id
          end
        end
        @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).query(@page, 20).videos.order(session, @orderby, @ascending).exec()
      rescue ProjectVinyl::Search::LexerError => e
        @derpy = e
      #rescue Exception => e
       # @ditzy = e
      end
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
        @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).query(@page, 20).users.order(session, @orderby, @ascending).exec()
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
        @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).query(@page, 20).videos.order(session, @orderby, @ascending).exec()
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
    reject = params[:validate] == '1' && user_signed_in? ? !current_user.validate_name(@query) : false
    if !@query || @query == ''
      render json: {
        content: [],
        match: 0,
        reject: reject
      }
    else
      render json: {
        content: User.where('username LIKE ?', "%#{@query}%").uniq.limit(8).pluck(:id, :username),
        match: 1,
        reject: reject
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

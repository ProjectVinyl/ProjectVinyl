require 'projectvinyl/elasticsearch/elastic_selector'

class SearchController < ApplicationController
  def index
    @type_label = params[:type]
    @type = @type_label.to_i
    @page = params[:page].to_i
    @ascending = params[:order] == '1'
    @orderby = params[:orderby].to_i
    @results = []
    
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
    else
      @query = @title_query = params[:query] || ""
    end
    
    if @type == 1
      @type_label= 'Album'
      @results = Album.where('title LIKE ?', "%#{@query}%")
      @results = Pagination.paginate(orderBy(@results, @type, @orderby), @page, 20, !@ascending)
    elsif @type == 3
      @type_label = 'Tag'
      @results = Tag.includes(:videos, :tag_type).where('name LIKE ?', "%#{@query}%")
      @results = Pagination.paginate(orderBy(@results, @type, @orderby), @page, 20, !@ascending)
    else
      try do
        if @type == 2
          @type_label = 'User'
          @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).query(@page, 20).users.order(session, @orderby, @ascending).exec()
          return
        end
        if params[:quick]
          @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).query(0, 1).videos.order_by('v.id').offset(-1).exec()
          @tags = @results.tags
          if @results.first
            return redirect_to action: 'view', controller: 'embed', id: @results.first.id
          end
        end
        @type_label = 'Song'
        @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).query(@page, 20).videos.order(session, @orderby, @ascending).exec()
      end
      if !@derpy
        @tags = @results.tags
      end
    end
  end
  
  def page
    @query = params[:tagquery]
    @page = params[:page].to_i
    @type = params[:type].to_i
    @ascending = params[:order] == '1'
    @orderby = params[:orderby].to_i
    if params[:query]
      if @type == 1
        return render_search_results_json(Pagination.paginate(orderBy(Album.where('title LIKE ?', "%#{@query}%"), @type, @orderby), @page, 20, !@ascending), 'album')
      elsif @type == 2
        return render_search_results_json(ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).query(@page, 20).users.order(session, @orderby, @ascending).exec(), 'artist')
      elsif @type == 3
        return render_search_results_json(Pagination.paginate(orderBy(Tag.includes(:videos, :tag_type).where('name LIKE ?', "%#{@query}%"), @type, @orderby), @page, 20, !@ascending), 'genre')
      else
        return render_search_results_json(ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).query(@page, 20).videos.order(session, @orderby, @ascending).exec(), 'video')
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
  
  private
  def render_search_results_json(results, type)
    return render json: {
      content: render_to_string(partial: '/layouts/' + type + '_thumb_h.html.erb', collection: results.records),
      pages: results.pages,
      page: results.page
    }
  end
  
  def try
    begin
      yield
    rescue ProjectVinyl::Search::LexerError => e
      @derpy = e
    rescue Exception => e
      @derpy = @ditzy = e
      puts "Exception raised #{e}"
      puts "Backtrace:\n\t#{e.backtrace[0..8].join("\n\t")}"
    end
  end
end

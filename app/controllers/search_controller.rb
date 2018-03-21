require 'projectvinyl/elasticsearch/elastic_selector'

class SearchController < ApplicationController
  Labels = ['Video', 'Album', 'User', 'Tag']
  Syms = [:videos, :albums, :users, :tags]
  
  def index
    merge_queries(params)
    
    if @type_sym == :albums || @type_sym == :tags
      @results = search_basic(@type, @page, @ascending)
      
      if @type_sym == :albums && @randomize
        index = rand * @results.count
        record = @results.offset(index).first
        return redirect_to action: :show, controller: :albums
      end
    else
      handle_derps do
        @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query)
        
        @results.videos.order(session, @orderby, @ascending)
        
        if params[:quick] && @type_sym == :videos
          if @single = @results.query(0, 1).exec.first
            return redirect_to action: 'view', controller: 'embed/videos', id: @single.id
          end
        end
        
        if @type_sym == :users
          @results.users
        end
        
        if @randomize
          if @single = @results.randomized(1).exec.first
            return redirect_to action: :show, controller: :videos, id: @single.id
          end
        end
        
        @results = @results.query(@page, 20).exec
        
        @tags = @results.tags
      end
    end
    
    if params[:format] == 'json'
      return render_pagination_json @partial, @results
    end
    
    @type_label = Labels[@type]
    @data = URI.encode_www_form(
      type: @type,
      order: params[:order],
      orderby: @orderby,
      query: @query
    )
  end
  
  private
  def merge_queries(params)
    @type = params[:type].to_i
    
    @type_sym = Syms[@type]
    @partial = partial_for_type(@type_sym)
    
    @page = params[:page].to_i
    @ascending = params[:order] == '1'
    @orderby = params[:orderby].to_i
    @randomize = params[:format] != 'json' && params[:random] == 'y'
    
    @query = @title_query = params[:query] || ""
    @tag_query = params[:tagquery] || ""
    
    if params[:format] != 'json'
      if @type == 2 || @type == 0
        @query = ""
        if !@title_query.empty?
          @query << "title:" + @title_query
        end
        if !@tag_query.empty? && !@query.empty?
          @query << ","
        end
        @query << @tag_query
      end
    end
    
    @results = []
  end
  
  def search_basic(type, page, ascending)
    if type == 1
      records = Album.where('title LIKE ?', "%#{@query}%").order(:created_at)
    else
      records = Tag.includes(:videos, :tag_type).where('name LIKE ?', "%#{@query}%").order(:name)
    end
    Pagination.paginate(records, page, 20, !ascending)
  end
  
  def handle_derps
    yield
  rescue ProjectVinyl::Search::LexerError => e
    @derpy = e
  rescue Exception => e
    @derpy = @ditzy = e
    puts "Exception raised #{e}"
    puts "Backtrace:\n\t#{e.backtrace[0..8].join("\n\t")}"
  end
end

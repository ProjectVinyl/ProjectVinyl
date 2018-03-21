require 'projectvinyl/elasticsearch/elastic_selector'

class SearchController < ApplicationController
  LABELS = ['Video', 'Album', 'User', 'Tag'].freeze
  SYMS = [:videos, :albums, :users, :tags].freeze
  
  def index
    read_params(params)
    
    if @type_sym == :albums || @type_sym == :tags
      @results = Pagination.paginate(search_basic, @page, 20, !@ascending)
      
      if @randomize && @type_sym == :albums && @single = @results.offset(rand * @results.count).first
        return redirect_to action: :show, controller: @type_sym, id: @single.id
      end
    else
      if params[:format] != 'json'
        merge_queries(params)
      end
      
      @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query)
      @results.order(session, @orderby, @ascending).videos
      
      if @type_sym == :users
        @results.users
      end
      
      if @randomize && @single = @results.randomized(1).exec.first
        return redirect_to action: :show, controller: @type_sym, id: @single.id
      end
      
      @results = @results.query(@page, 20).exec
      @tags = @results.tags
    end
    
    if params[:format] == 'json'
      return render_pagination_json @partial, @results
    end
    
    @type_label = LABELS[@type]
    @data = URI.encode_www_form(
      type: @type,
      order: params[:order],
      orderby: @orderby,
      query: @query
    )
  end
  
  private
  def read_params(params)
    @type = params[:type].to_i
    
    @type_sym = SYMS[@type]
    @partial = partial_for_type(@type_sym)
    
    @page = params[:page].to_i
    @ascending = params[:order] == '1'
    @orderby = params[:orderby].to_i
    @randomize = params[:format] != 'json' && params[:random] == 'y'
    
    @query = @title_query = params[:query] || params[:q] || ""
    @tag_query = params[:tagquery] || ""
    
    @results = []
  end
  
  def merge_queries(params)
    if @type_sym == :users || @type_sym == :videos
      @query = ""
      if !@title_query.empty?
        @query << "title:#{@title_query}"
      end
      if !@tag_query.empty? && !@query.empty?
        @query << ","
      end
      @query << @tag_query
    end
  end
  
  def search_basic
    if @type_sym == :albums
      return Album.where('title LIKE ?', "%#{@query}%").order(:created_at)
    end
    Tag.includes(:videos, :tag_type).where('name LIKE ?', "%#{@query}%").order(:name)
  end
end

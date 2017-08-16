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
      if !@title_query.empty?
        @query << "title:" + @title_query
      end
      if !@tag_query.empty? && !@query.empty?
        @query << ","
      end
      @query << @tag_query
    else
      @query = @title_query = params[:query] || ""
    end
    
    @data = URI.encode_www_form(
      type: @type,
      order: @ascending ? '1' : '0',
      orderby: @orderby, query: @query
    )
    
    if @type == 1 || @type == 3
      @results = search_basic(@type, @page, @ascending)
      @type_label = @type == 1 ? 'Album' : 'Tag'
    else
      handle_derps do
        @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).videos
        
        if params[:quick] && @type == 2
          if @single = @results.query(0, 1).order_by('v.id').exec.first
            return redirect_to action: 'view', controller: 'embed', id: @single.id
          end
        end
        
        @results = @results.query(@page, 20)
        @type_label = 'Video'
        
        if @type == 2
          @type_label = 'User'
          @results = @results.users
        end
        
        @results = @results.order(session, @orderby, @ascending).exec
        @tags = @results.tags
      end
    end
    
    @partial = partial_for_type(@type_label)
  end
  
  def page
    @query = params[:query]
    @page = params[:page].to_i
    @type = params[:type].to_i
    @ascending = params[:order] == '1'
    
    if !@query
      return head 401
    end
    
    if @type == 1 || @type == 3
      @results = search_basic(@type, @page, @ascending)
      @type = @type == 1 ? :album : :tag
    else
      @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).query(@page, 20).videos
      @type = :video
      
      if @type == 2
        @results = @results.users
        @type = :user
      end
      
      @results = @results.order(session, params[:orderby].to_i, @ascending).exec
    end
    render_pagination_json partial_for_type(@type), @results
  end
  
  def search_basic(type, page, ascending)
    if type == 1
      records = Album.where('title LIKE ?', "%#{@query}%").order(:created_at)
    else
      records = Tag.includes(:videos, :tag_type).where('name LIKE ?', "%#{@query}%").order(:name)
    end
    Pagination.paginate(records, page, 20, !ascending)
  end
  
  private
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

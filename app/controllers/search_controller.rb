require 'projectvinyl/elasticsearch/elastic_selector'

class SearchController < ApplicationController
  def index
    read_params(params)

    @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query)
    @results.videos
    @results.order(session, @orderby, @ascending)
    
    if @randomize && @single = @results.randomized(1).exec.records.first
      return redirect_to action: :show, controller: @type_sym, id: @single.id
    end
    
    @results = @results.query(@page, 20).exec
    @tags = @results.tags
    
    if params[:format] == 'json'
      return render_pagination_json @partial, @results
    end
    
    @type_label = 'Video'
    @data = URI.encode_www_form(
      type: @type,
      order: params[:order],
      orderby: @orderby,
      query: @query
    )
    @crumb = {
      stack: [
        {
          title: "Search"
        }
      ],
      title: @type_label.pluralize
    }
  end
  
  private
  def read_params(params)
    @type = params[:type].to_i
    @partial = partial_for_type(:videos)
    
    @page = params[:page].to_i
    @ascending = (params[:order] || 0).to_i == 0
    @orderby = params[:orderby].to_i
    @randomize = params[:format] != 'json' && params[:random] == 'y'
    
    @title_query = params[:tq] || ''
    @tag_query = params[:q] || ''
    
    if params[:format] == 'json'
      @query = params[:tq] || params[:q] || ""
    else
      @query = ""
      if !@title_query.empty?
        @query << "title:#{@title_query}"
      end
      if !@tag_query.empty? && !@query.empty?
        @query << ","
      end
      @query << @tag_query
    end

    @results = []
  end
end

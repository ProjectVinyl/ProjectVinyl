require 'projectvinyl/elasticsearch/elastic_selector'

class SearchController < ApplicationController
  def index
    read_params(params)

    @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query).videos
    @results.order(session, @orderby, @ascending)
    
    if @randomize && @single = @results.randomized(1).exec.records.first
      return redirect_to action: :show, controller: :videos, id: @single.id
    end
    
    @results = @results.query(@page, 20).exec
    @tags = @results.tags
    
    if params[:format] == 'json'
      return render_pagination_json @partial, @results
    end

    @data = URI.encode_www_form(
      order: params[:order],
      orderby: @orderby,
      query: @query
    )
    @crumb = {
      stack: [
        {
          title: 'Videos',
          link: '/videos'
        }
      ],
      title: 'Search'
    }
  end
  
  private
  def read_params(params)
    @partial = partial_for_type(:videos)
    
    @page = params[:page].to_i
    @ascending = (params[:order] || 0).to_i == 0
    @orderby = params[:orderby].to_i
    @randomize = params[:format] != 'json' && params[:random] == 'y'
    @query = params[:q] || ""
  end
end

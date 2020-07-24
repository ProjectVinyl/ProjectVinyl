require 'projectvinyl/elasticsearch/elastic_selector'

class SearchController < ApplicationController
  include Searchable

  configure_ordering [ :date, :rating, :heat, :length, :random, :relevance ], {
    query_term: 'q'
  }

  def index
    read_search_params(params)
    @partial = partial_for_type(:videos)
    @randomize = params[:format] != 'json' && params[:random] == 'y'

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
      order: @order,
      orderby: @orderby,
      query: @query
    )
    @crumb = {
      stack: [
        { title: 'Videos', link: '/videos' }
      ],
      title: 'Search'
    }
  end
end

require 'projectvinyl/search/search'

class SearchController < ApplicationController
  include Searchable

  configure_ordering [ :date, :rating, :heat, :length, :random, :relevance ], {
    query_term: 'q'
  }

  def index
    read_search_params(params)
    @partial = partial_for_type(:videos)
    @randomize = params[:format] != 'json' && params[:random] == 'y'

    @results = ProjectVinyl::Search.paginate(current_user, @query, ProjectVinyl::Search::VIDEO_INDEX_PARAMS)
    @results.ordering = ProjectVinyl::Search.ordering('video', session, @orderby, @ascending)

    if @randomize && @single = @results.randomized(1).exec.records.first
      return redirect_to action: :show, controller: :videos, id: @single.id
    end

    @results = @results.query(@page, 20).exec
    @tags = @results.tags

    return render_pagination_json @partial, @results if params[:format] == 'json'

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

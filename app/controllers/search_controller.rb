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

    @results = current_filter.videos.sort(ProjectVinyl::Search.ordering('video', session, @orderby, @ascending))

    if !@query.strip.empty?
      parsed_query = current_filter.build_params(@query, current_user)
      @results = @results.must(parsed_query.to_hash).excepted(parsed_query)
      @tags = Tag.get_tags(parsed_query.tags)
    end

    if @randomize && @single = @results.limit(1).random.first
      return redirect_to action: :show, controller: :videos, id: @single.id
    end

    @results = @results.paginate(@page, 20)

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

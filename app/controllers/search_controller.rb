class SearchController < ApplicationController
  def index
    @query = params[:query]
    @type_label = params[:type]
    @type = @type_label.to_i
    @ascending = params[:order] == '1'
    @orderby = params[:orderby].to_i
    @results = []
    if params[:query]
      if @type == 1
        @results = Album.where('title LIKE ?', "%#{@query}%")
        @type_label= 'Album'
      else
        if @type == 2
          @results = Artist.where('name LIKE ?', "%#{@query}%")
          @type_label = 'Artist'
        else
          if @type == 3
            @type_label = 'Genre'
          else
            @results = Video.where('title LIKE ?', "%#{@query}%")
            @type_label = 'Song'
          end
        end
      end
    end
  end
end

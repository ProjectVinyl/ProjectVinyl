module Tags
  class ImpliedController < ApplicationController
    def index
      @implied = Tag.includes(:implications).references(:implications).where('tag_implications.id IS NOT NULL').order(:name)
      @implied = Pagination.paginate(@implied, params[:page].to_i, 10, true)
      
      render_pagination_json 'tags/tag_implication', @implied if params[:format] == 'json'
    end
  end
end

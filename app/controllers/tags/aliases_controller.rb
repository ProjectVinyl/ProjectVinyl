module Tags
  class AliasesController < ApplicationController
    def index
      @aliases = Tag.includes(:alias => [:videos, :users]).where('alias_id > 0').order(:name)
      @aliases = Pagination.paginate(@aliases, params[:page].to_i, 10, true)

      render_pagination_json 'tags/tag_alias', @aliases if params[:format] == 'json'
    end
  end
end

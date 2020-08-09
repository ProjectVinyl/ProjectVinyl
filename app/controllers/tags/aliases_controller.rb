module Tags
  class AliasesController < ApplicationController
    def index
      @aliases = Tag.includes(:alias => [:videos, :users]).where('alias_id > 0').order(:name)
      @aliases = Pagination.paginate(@aliases, params[:page].to_i, 10, true)

      render_paginated @aliases, partial: 'tags/tag_alias', as: :json if params[:format] == 'json'
    end
  end
end

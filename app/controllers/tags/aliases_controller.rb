module Tags
  class AliasesController < ApplicationController
    def index
      @aliases = Tag.includes(:alias => [:videos, :users]).where('alias_id > 0').order(:name)
      @aliases = Pagination.paginate(@aliases, params[:page].to_i, 20, params[:order].to_i == 1)

      render_paginated @aliases, partial: 'tags/aliases/row', headers: 'column_headers', as: :json if params[:format] == 'json'
    end
  end
end

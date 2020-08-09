module Tags
  class ImpliedController < ApplicationController
    def index
      @implied = Tag.includes(:implications).references(:implications).where('tag_implications.id IS NOT NULL').order(:name)
      @implied = Pagination.paginate(@implied, params[:page].to_i, 10, true)
      
      render_paginated @implied, partial: 'tags/tag_implication', headers: 'column_headers', as: :json if params[:format] == 'json'
    end
  end
end

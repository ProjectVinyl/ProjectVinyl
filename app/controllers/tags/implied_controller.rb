module Tags
  class ImpliedController < ApplicationController
    def index
      @implied = Tag.includes(:implications).references(:implications).where('tag_implications.id IS NOT NULL').order(:name)
      @implied = Pagination.paginate(@implied, params[:page].to_i, 20, params[:order].to_i == 1)
      
      render_paginated @implied, partial: 'tags/implied/row', headers: 'column_headers', as: :json if params[:format] == 'json'
    end
  end
end

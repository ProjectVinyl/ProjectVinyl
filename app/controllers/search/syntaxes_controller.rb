
module Search
  class SyntaxesController < ApplicationController
    def show
      return render partial: 'search/syntaxes/content', formats: [:html] if params[:format] == 'json'
    end
  end
end

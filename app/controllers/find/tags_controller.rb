module Find
  class TagsController < ApplicationController
    def index
			term = params[:q].strip.split(/,|;/).last.strip.downcase
      render json: {
				term: term,
        results: Tag.by_name_or_slug(term, current_user)
      }
    end
  end
end

module Find
  class TagsController < ApplicationController
    def index
			term = params[:q].strip.split(/,|;/).last.strip.downcase
      render json: {
				term: term,
        results: Tag.find_matching_tags(term, current_user)
      }
    end
  end
end

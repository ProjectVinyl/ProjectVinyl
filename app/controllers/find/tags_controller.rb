module Find
  class TagsController < ApplicationController
    def index
      term = Tag.split_to_names(params[:q]).last
      render json: {
        term: term || '',
        results: Tag.by_name_or_slug(term)
                    .ordered
                    .limit(10)
                    .jsons(current_user)
      }
    end
  end
end

module Find
  class TagController < ApplicationController
    def find
      render json: {
        results: Tag.find_matching_tags(params[:q])
      }
    end
  end
end

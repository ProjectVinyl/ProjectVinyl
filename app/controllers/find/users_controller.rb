module Find
  class UsersController < ApplicationController
    def index
      @query = params[:q]
      reject = params[:validate] && user_signed_in? ? !current_user.validate_name(@query) : false
      
      if !@query || @query == ''
        return render json: {
					term: @query,
          results: [],
          reject: reject
        }
      end
      
      render json: {
				term: @query,
        results: User.find_matching_users(@query),
        reject: reject
      }
    end
  end
end

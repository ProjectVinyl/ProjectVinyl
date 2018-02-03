module Find
  class UserController < ApplicationController
    def find
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
        results: User.where('username LIKE ?', "%#{@query}%").limit(8).uniq.pluck(:id, :username),
        reject: reject
      }
    end
  end
end

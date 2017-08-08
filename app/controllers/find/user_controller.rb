module Find
  class UserController < ApplicationController
    def find
      @query = params[:query]
      reject = params[:validate] == '1' && user_signed_in? ? !current_user.validate_name(@query) : false
      
      if !@query || @query == ''
        return render json: {
          content: [],
          match: 0,
          reject: reject
        }
      end
      
      render json: {
        content: User.where('username LIKE ?', "%#{@query}%").uniq.limit(8).pluck(:id, :username),
        match: 1,
        reject: reject
      }
    end
  end
end

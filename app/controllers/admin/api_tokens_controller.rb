module Admin
  class ApiTokensController < ApplicationController
    before_action :authenticate_user!
    
    def index
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' }
        ],
        title: "Api Tokens"
      }
      @tokens = ApiToken.includes(:user).all
    end
  end
end

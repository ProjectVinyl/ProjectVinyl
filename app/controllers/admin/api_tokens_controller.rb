module Admin
  class ApiTokensController < BaseAdminController
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
    
    def new
      @token = ApiToken.new
      render partial: 'new'
    end
    
    def create
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      redirect_to action: :index
      
      if !(@user = User.get_as_recipients(params[:token][:user]).first)
        flash[:error] = "Error: User not found.";
        return
      end
      
      if !ApiToken.create_new_token(@user)
        flash[:error] = "Error: That user already has a token. You can't create more than one.";
      end
    end
    
    def destroy
      redirect_to action: :index
      
      if !current_user.is_contributor?
        return flash[:error] = "Error: Login required."
      end
      
      if !(@token = ApiToken.where(id: params[:id]).first)
        return flash[:error] = "Error: Record not found."
      end
      
      @token.destroy
      flash[:notice] = "Record deleted.";
    end
    
    def update
      redirect_to action: :index
      
      if !current_user.is_contributor?
        return flash[:error] = "Error: Login required."
      end
      
      if !(@token = ApiToken.where(id: params[:id]).first)
        return flash[:error] = "Error: Record not found."
      end
      
      @token.reset
      flash[:notice] = "Token reset.";
    end
  end
end

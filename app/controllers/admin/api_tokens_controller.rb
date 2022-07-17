module Admin
  class ApiTokensController < BaseAdminController
    def index
      return render_access_denied if !current_user.is_contributor?
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
      return render_access_denied if !current_user.is_contributor?
      redirect_to action: :index

      return flash[:error] = "Error: User not found" if !(@user = User.as_recipients(params[:token][:user]).first)
      flash[:error] = "Error: That user already has a token. You can't create more than one." if !ApiToken.create_new_token(@user)
    end

    def destroy
      redirect_to action: :index
      return flash[:error] = "Error: Login required" if !current_user.is_contributor?
      return flash[:error] = "Error: Record not found" if !(@token = ApiToken.where(id: params[:id]).first)

      @token.destroy
      flash[:notice] = "Record deleted."
    end

    def update
      redirect_to action: :index
      return flash[:error] = "Error: Login required" if !current_user.is_contributor?
      return flash[:error] = "Error: Record not found" if !(@token = ApiToken.where(id: params[:id]).first)

      @token.reset
      flash[:notice] = "Token reset";
    end
  end
end

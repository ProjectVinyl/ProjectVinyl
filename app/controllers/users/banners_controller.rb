module Users
  class BannersController < BaseUsersController
    def show
      check_then do |user|
        @user = user
        render partial: 'show'
      end
    end

    def update
      check_then do |user|
        if params[:erase] || params[:user][:banner]
          user.banner = params[:erase] ? false : params[:user][:banner]
          user.save
        end
        
        if params[:format] == 'json'
          return render json: {
            result: "success"
          }
        end
        
        redirect_to action: :view, id: user.id
      end
    end
  end
end
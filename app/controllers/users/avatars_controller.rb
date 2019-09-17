module Users
  class AvatarsController < Users::BaseUsersController
    def update
      check_then do |user|
        user.avatar = params[:erase] ? false : params[:user][:avatar]
        user.save
        
        if params[:format] == 'json'
          return render json: {
            result: "success"
          }
        end
        
        redirect_to action: :edit, controller: "registrations"
      end
    end
  end
end

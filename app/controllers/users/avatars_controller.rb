module Users
  class AvatarsController < Users::BaseUsersController
    def update
      check_then do |user|
        user.avatar = params[:erase] ? false : params[:user][:avatar]
        user.save
        
        return redirect_to action: :edit, controller: "registrations" if params[:format] != 'json'
        render json: {
          result: "success"
        }
      end
    end
  end
end

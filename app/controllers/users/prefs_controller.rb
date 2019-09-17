module Users
  class PrefsController < Users::BaseUsersController
    def put
      if user_signed_in?
        current_user.prefs_cache.save(params[:settings])
      end
      redirect_to action: :edit, controller: "users/registrations"
    end
  end
end

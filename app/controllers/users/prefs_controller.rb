module Users
  class PrefsController < Users::BaseUsersController
    def put
      current_user.prefs_cache.save(params[:settings]) if user_signed_in?
      redirect_to action: :edit, controller: "users/registrations"
    end
  end
end

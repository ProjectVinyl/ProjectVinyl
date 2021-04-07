module Users
  class ProfileModulesController < Users::BaseUsersController

    def create
      check_details_then do |user, edits_allowed|
        user.profile_modules.create(params.permit(:module_type, :column, :index))
        head :ok
      end
    end

    def update
      check_details_then do |user, edits_allowed|
        if item = user.profile_modules.where(id: params[:id].to_i).first
          item.column = params[:profile_column_id].to_i
          item.move(params[:index].to_i)
          head :ok
        end
      end
    end
    
    def destroy
      check_details_then do |user, edits_allowed|
        user.profile_modules.where(id: params[:id]).destroy_all
        head :ok
      end
    end
  end
end

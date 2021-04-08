module Users
  class ProfileModulesController < Users::BaseUsersController

    def create
      check_details_then do |user, edits_allowed|
        @pars = params[:part].permit(:module_type, :column, :index)

        @pars[:module_type] = ProfileModule.module_types[@pars[:module_type].to_i]

        if @pars[:index].to_i == -1
          @max = user.profile_modules.where(column: @pars[:column]).pluck('MAX(index)').first
          @pars[:index] = @max.nil? ? 0 : (@max.to_i + 1)
        end

        @modifications_allowed = true
        part = user.profile_modules.create(@pars)
        load_profile_module part.module_type

        render json: {
          target: "##{ProfileModule.profile_column_types[part.column]}-column",
          index: part.index,
          html: render_to_string(partial: 'users/profile_modules/part', locals: {part: part}, formats: [:html])
        }
      end
    end

    def new
      @part = ProfileModule.new(params.permit(:user_id, :column, :index))
      render partial: 'new', formats: [:html]
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

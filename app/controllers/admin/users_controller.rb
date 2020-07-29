module Admin
  class UsersController < BaseAdminController
    def show
      return render_access_denied if !current_user.is_contributor?
      @user = User.find(params[:id])
      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' },
          { link: @user.link, title: @user.id }
        ],
        title: @user.username
      }
    end

    def destroy
      if @user = User.find(params[:id])

        if @user.banned? || @user.normal?
          @user.destroy
          flash[:notice] = "User account #{@user.username} has been deleted."

          return redirect_to action: :index, controller: 'admin/admin'
        end

        flash[:notice] = "The user account cannot be deleted because it has moderation/contributor privilages."
      end

      redirect_to action: :show
    end
  end
end

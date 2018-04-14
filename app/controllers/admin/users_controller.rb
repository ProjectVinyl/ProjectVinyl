module Admin
  class UsersController < BaseAdminController
    def show
      if !current_user.is_contributor?
        return render_access_denied
      end
      @user = User.find(params[:id])
      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' },
          { link: @user.link, title: @user.id }
        ],
        title: @user.username
      }
    end
  end
end

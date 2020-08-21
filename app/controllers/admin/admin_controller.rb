module Admin
  class AdminController < BaseAdminController
    def index
      return render_access_denied if !current_user.is_contributor?

      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' }
        ],
        title: "Control Panel"
      }

      @tables = [:video, :user, :tag]

      @hiddenvideos = Pagination.paginate(Video.where(hidden: true).with_likes(current_user), params[:hidden].to_i, 40, true)
      @unprocessed = Pagination.paginate(Video.where("(processed IS NULL or processed = ?) AND hidden = false", false).with_likes(current_user), params[:unprocessed].to_i, 40, false)
      @reports = Pagination.paginate(Report.includes(:reportable).open, params[:reports].to_i, 40, false)
      @users = Pagination.paginate(User.active_since(Time.zone.now - 2.month).reverse_order, params[:users].to_i, 40, false)
    end
  end
end

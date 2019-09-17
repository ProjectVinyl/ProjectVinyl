module Admin
  class AdminController < BaseAdminController
    def view
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' }
        ],
        title: "Control Panel"
      }
      
      @hiddenvideos = Pagination.paginate(Video.where(hidden: true).with_likes(current_user), params[:hidden].to_i, 40, true)
      @unprocessed = Pagination.paginate(Video.where("(processed IS NULL or processed = ?) AND hidden = false", false).with_likes(current_user), params[:unprocessed].to_i, 40, false)
      @users = User.where('last_active_at > ? OR updated_at > ?', Time.zone.now.beginning_of_month, Time.zone.now.beginning_of_month).limit(100).order(:last_active_at).reverse_order
      @reports = Pagination.paginate(Report.includes(:reportable).open, params[:reports].to_i, 40, false)
    end
  end
end

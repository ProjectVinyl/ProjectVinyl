module Admin
  class SitenoticesController < BaseAdminController
    
    def index
      return render_access_denied if !current_user.is_contributor?

      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' }
        ],
        title: "Site Notices"
      }
      @page = params[:page].to_i
      @notices = SiteNotice.all #Pagination.paginate(SiteNotice.all, @page, 40, true)
    end
    
    def new
      @notice = SiteNotice.new
      render partial: 'new'
    end
    
    def create
      return render_access_denied if !current_user.is_contributor?
      redirect_to action: :index
      
      if !params[:notice][:message]
        flash[:error] = "Error: Message field is required.";
        return
      end

      @notice = SiteNotice.create(params[:notice].permit(:active, :message))
    end
    
    def update
      return render_access_denied if !current_user.is_contributor?
      redirect_to action: :index
      
      if !(@notice = SiteNotice.where(id: params[:notice][:id]).first)
        flash[:error] = "Error: Record not found.";
      end
      
      @notice.message = params[:notice][:message]
      @notice.active = params[:notice][:active]
      @notice.save
      flash[:notice] = "Changes saved.";
    end
    
    def destroy
      redirect_to action: :index
      return flash[:error] = "Error: Login required." if !current_user.is_contributor?
      return flash[:error] = "Error: Record not found." if !(@notice = SiteNotice.where(id: params[:id]).first)

      @notice.destroy
      flash[:notice] = "Record deleted.";
    end
  end
end

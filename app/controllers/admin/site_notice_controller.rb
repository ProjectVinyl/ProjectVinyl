module Admin
  class SiteNoticeController < BaseAdminController
    
    def index
      if !current_user.is_contributor?
        return render_access_denied
      end
      
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
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      redirect_to action: :index
      
      if !params[:notice][:message]
        flash[:error] = "Error: Message field is required.";
        return
      end
      
      @notice = SiteNotice.create({
          active: params[:notice][:active],
          message: text,
          html_message: BbcodeHelper.emotify(text)
      })
    end
    
    def update
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      redirect_to action: :index
      
      if !(@notice = SiteNotice.where(id: params[:notice][:id]).first)
        flash[:error] = "Error: Record not found.";
      end
      
      @notice.set_message(params[:notice][:message])
      @notice.active = params[:notice][:active]
      @notice.save
      flash[:notice] = "Changes saved.";
    end
    
    def destroy
      redirect_to action: :index
      
      if !current_user.is_contributor?
        return flash[:error] = "Error: Login required."
      end
      
      if !(@notice = SiteNotice.where(id: params[:id]).first)
        return flash[:error] = "Error: Record not found."
      end
      
      @notice.destroy
      flash[:notice] = "Record deleted.";
    end
  end
end

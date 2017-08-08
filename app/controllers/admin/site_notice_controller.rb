module Admin
  class SiteNoticeController < ApplicationController
    before_action :authenticate_user!
    
    def index
      if !current_user.is_contributor?
        return render 'layouts/error', locals: {
          title: 'Access Denied',
          description: "You can't do that right now."
        }
      end
      
      @page = params[:page].to_i
      @notices = SiteNotice.all #Pagination.paginate(SiteNotice.all, @page, 40, true)
    end
    
    def new
      @notice = SiteNotice.new
      render partial: 'new'
    end
    
    def create
      if !current_user.is_contributor?
        return render 'layouts/error', locals: {
          title: 'Access Denied',
          description: "You can't do that right now."
        }
      end
      
      redirect_to action: "index"
      
      if !params[:notice][:message]
        flash[:error] = "Error: Message field is required.";
      end
      
      text = ApplicationHelper.demotify(params[:notice][:message])
      @notice = SiteNotice.create({
          active: params[:notice][:active],
          message: text, html_message: ApplicationHelper.emotify(text)
      })
    end
    
    def update
      if !current_user.is_contributor?
        return render 'layouts/error', locals: {
          title: 'Access Denied',
          description: "You can't do that right now."
        }
      end
      
      redirect_to action: "index"
      
      if !(@notice = SiteNotice.where(id: params[:notice][:id]).first)
        flash[:error] = "Error: Record not found.";
      end
      
      @notice.set_message(params[:notice][:message])
      @notice.active = params[:notice][:active]
      @notice.save
      flash[:notice] = "Changes saved.";
    end
    
    def delete
      redirect_to action: "view"
      
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

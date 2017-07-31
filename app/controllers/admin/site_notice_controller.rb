module Admin
  class SiteNoticeController < ApplicationController
    def index
      if !user_signed_in? || !current_user.is_contributor?
        return render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      end
      
      @page = params[:page].to_i
      @notices = SiteNotice.all #Pagination.paginate(SiteNotice.all, @page, 40, true)
    end
    
    def new
      @notice = SiteNotice.new
      render partial: 'new'
    end
    
    def create
      if !user_signed_in? || !current_user.is_contributor?
        return render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      end
      
      if !params[:notice][:message]
        flash[:error] = "Error: Message field is required.";
      end
      
      text = ApplicationHelper.demotify(params[:notice][:message])
      @notice = SiteNotice.create(
          active: params[:notice][:active],
          message: text, html_message: ApplicationHelper.emotify(text)
      )
      
      return redirect_to action: "index"
    end
    
    def update
      if user_signed_in? && current_user.is_contributor?
        if @notice = SiteNotice.where(id: params[:notice][:id]).first
          @notice.set_message(params[:notice][:message])
          @notice.active = params[:notice][:active]
          @notice.save
          flash[:notice] = "Changes saved.";
        else
          flash[:error] = "Error: Record not found.";
        end
        return redirect_to action: "view"
      end
      
      return render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
    end
    
    def delete
      if user_signed_in? && current_user.is_contributor?
        if @notice = SiteNotice.where(id: params[:id]).first
          @notice.destroy
          flash[:notice] = "Record deleted.";
        end
      end
      return redirect_to action: "view"
    end
  end
end

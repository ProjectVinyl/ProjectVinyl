module Admin
  class BadgesController < BaseAdminController
    def index
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' }
        ],
        title: "Badges"
      }
      @badges = Badge.all
    end
    
    def new
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      @badge = Badge.new
      render partial: 'new'
    end
    
    def create
      check_first do
        @badge = params[:badge]
        @badge = Badge.create(
          title: @badge[:title],
          colour: @badge[:colour],
          icon: @badge[:icon],
          badge_type: @badge[:badge_type],
          note: @badge[:note],
          description: @badge[:description],
          hidden: @badge[:hidden]
        )
      end
    end
    
    def update
      check_then do
        @badge.title = params[:badge][:title]
        @badge.colour = params[:badge][:colour]
        @badge.icon = params[:badge][:icon]
        @badge.badge_type = params[:badge][:badge_type]
        @badge.note = params[:badge][:note]
        @badge.description = params[:badge][:description]
        @badge.hidden = params[:badge][:hidden]
        @badge.save
      end
    end
    
    def destroy
      check_then do
        @badge.destroy
        flash[:notice] = "Record deleted.";
      end
    end
    
    private
    def check_first
      redirect_to action: :index
      
      if !current_user.is_contributor?
        return flash[:error] = "Error: Login required."
      end
      
      yield
    end
    
    def check_then
      check_first do
        if !(@badge = Badge.where(id: params[:id]).first)
          return flash[:error] = "Error: Record not found."
        end
        
        yield
      end
    end
  end
end

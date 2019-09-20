module Inbox
  class PmController < BaseInboxController
    before_action :check_requirements, only: [:destroy]
    
    def show
      if !(user_signed_in? && @pm = Pm.find_for_user(params[:id], current_user))
        return render_error(
          title: 'Nothing to see here!',
          description: "Either the thread does not exist or you don't have the necessary permissions to see it."
        )
      end
      
      @order = '0'
      @thread = @pm.comment_thread
      @comments = Pagination.paginate(@thread.get_comments(current_user), (params[:page] || -1).to_i, 10, false)
      @crumb = {
        stack: [
          { link: "/inbox", title: "Messages" }
        ],
        title: @thread.get_title
      }
      if @pm.unread
        @pm.unread = false
        @pm.save
      end
    end
    
    def new
      @thread = CommentThread.new
      if params[:user]
        @user = User.where(id: params[:user]).first
      end
      render partial: 'new'
    end
    
    def create
      if !user_signed_in?
        return redirect_to action: :index, controller: :welcome
      end
      
      recipients = User.get_as_recipients(params[:thread][:recipient])
      
      if recipients.length == 0
        return redirect_to action: :index, controller: :welcome
      end
      
      redirect_to action: :show, id: Pm.send_pm(current_user, recipients, params[:thread][:title], params[:thread][:description]).id
    end

    def destroy
      @pm.toggle_deleted
      
      @type = params[:type]
      @results = paginate_for_type(@type)
      
      @json = pagination_json_for_render 'inbox/pm/thumb', @results
      @json[:tabs] = tab_changes
      render json: @json
    end
  end
end
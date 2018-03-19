class PmController < InboxController
  def show
    if !(user_signed_in? && @pm = Pm.find_for_user(params[:id], current_user))
      return render_error(
        title: 'Nothing to see here!',
        description: "Either the thread does not exist or you don't have the neccessary permissions to see it."
      )
    end
    
    @order = '0'
    @thread = @pm.comment_thread
    @comments = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_contributor?), (params[:page] || -1).to_i, 10, false)
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
    if !user_signed_in? || !(user = User.where(username: params[:thread][:recipient]).first)
      return redirect_to action: "index", controller: "welcome"
    end
    redirect_to action: :show, id: Pm.send_pm(current_user, user, params[:thread][:title], params[:thread][:description]).id
  end
  
  def markread
    check_then do |pm|
      pm.unread = !pm.unread
      pm.save
      render json: {
        added: pm.unread,
        tabs: tab_changes
      }
    end
  end
  
  def destroy
    check_then do |pm|
      pm.toggle_deleted
      
      @type = params[:type]
      @results = paginate_for_type(@type)
      
      @json = pagination_json_for_render 'pm/thumb', @results
      @json[:tabs] = tab_changes
      render json: @json
    end
  end
  
  protected
  def check_then
    if !user_signed_in?
      return head 403
    end
    
    if !(pm = Pm.find_for_user(params[:message_id], current_user))
      return head 404
    end
    
    yield(pm)
  end
end

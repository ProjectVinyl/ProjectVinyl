class PmController < ApplicationController
  def index
    @type = params[:type] || 'new'
    @result = paginate_for_type(@type)
    @counts = tab_changes
  end
  
  def view
    if !(user_signed_in? && @pm = Pm.find_for_user(params[:id], current_user))
      return render_error(
        title: 'Nothing to see here!',
        description: "Either the thread does not exist or you don't have the neccessary permissions to see it."
      )
    end
    @order = '0'
    @thread = @pm.comment_thread
    @comments = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_contributor?), (params[:page] || -1).to_i, 10, false)
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
    redirect_to action: 'view', id: Pm.send_pm(current_user, user, params[:thread][:title], params[:thread][:description]).id
  end
  
  def page
    @type = params[:type]
    @results = paginate_for_type(@type)
    if @results.count == 0
      return render_empty_pagination 'pm/mailderpy'
    end
    @json = pagination_json_for_render 'pm/thumb', @results
    @json[:tabs] = tab_changes
    render json: @json
  end
  
  def tab
    @type = params[:type]
    render json: {
      content: render_to_string(partial: 'pm/list_group', locals: {
        type: @type,
        paginated: paginate_for_type(@type),
        selected: true
      }),
      tabs: tab_changes
    }
  end
  
  def mark_read
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
  
  private
  def tab_changes(type = nil, results = nil)
    {
      new: count_for_type('new')
    }
  end
  
  def check_then
    if !user_signed_in?
      return head 403
    end
    
    if !(pm = Pm.find_for_user(params[:id], current_user))
      return head 404
    end
    
    yield(pm)
  end
  
  def count_for_type(type)
    Pm.find_for_tab_counter(type, current_user).count
  end
  
  def page_for_type(type)
    Pm.find_for_tab(type, current_user)
  end
  
  def paginate_for_type(type)
    Pagination.paginate(page_for_type(type), params[:page].to_i, 50, false)
  end
end

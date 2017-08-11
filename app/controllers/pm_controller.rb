class PmController < ApplicationController
  def index
    @type = params[:type] || 'new'
    @result = paginate_for_type(@type)
    @new = @type == 'new' ? @result.count : page_for_type('new').count
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
    render partial: 'new'
  end
  
  def create
    if !user_signed_in? || !(user = User.where(username: params[:thread][:recipient]).first)
      return redirect_to action: "index", controller: "welcome"
    end
    redirect_to action: 'view', id: Pm.send_pm(current_user, user, params[:thread][:title], params[:thread][:description]).id
  end
  
  def page
    @results = paginate_for_type(params[:type])
    if @results.count == 0
      return render_empty_pagination 'pm/mailderpy'
    end
    render_pagination_json 'pm/thumb', @results
  end
  
  def tab
    render json: {
      content: render_to_string(partial: 'pm/list_group', locals: {
        type: params[:type],
        paginated: paginate_for_type(params[:type]),
        selected: true
      })
    }
  end
  
  def mark_read
    check_then do
      render json: {
        added: pm.unread = !pm.unread
      }
      pm.save
    end
  end
  
  def destroy
    check_then do |pm|
      pm.toggle_deleted
      
      @results = paginate_for_type(params[:type])
      if @results.count == 0
        return render_empty_pagination 'pm/mailderpy'
      end
      
      render_pagination_json 'pm/thumb', @results
    end
  end
  
  private
  def check_then
    if !user_signed_in?
      return head 403
    end
    
    if !(pm = Pm.find_for_user(params[:id], current_user))
      return head 404
    end
    
    yield(pm)
  end
  
  def page_for_type(type)
    Pm.find_for_tab(type, current_user)
  end
  
  def paginate_for_type(type)
    Pagination.paginate(page_for_type(type), params[:page].to_i, 50, false)
  end
end

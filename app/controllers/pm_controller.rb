class PmController < ApplicationController
  def index
    @page = params[:page].to_i
    @type = params[:type] || 'new'
    @result = Pagination.paginate(page_for_type(@type), @page, 50, false)
    if @type == 'new'
      @new = @result.count
    else
      @new = page_for_type('new').count
    end
  end
  
  def view
    if !(user_signed_in? && @pm = Pm.find_for_user(params[:id], current_user))
      return render 'layouts/error', locals: { title: 'Nothing to see here!', description: "Either the thread does not exist or you don't have the neccessary permissions to see it." }
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
    if user_signed_in?
      if user = User.where(username: params[:thread][:recipient]).first
        return redirect_to action: 'view', id: Pm.send_pm(current_user, user, params[:thread][:title], params[:thread][:description]).id
      end
    end
    redirect_to action: "index", controller: "welcome"
  end
  
  def page_for_type(type)
    Pm.find_for_tab(type, current_user)
  end
  
  def page
    @page = params[:page].to_i
    @results = Pagination.paginate(page_for_type(params[:type]), @page, 50, false)
    if @results.count == 0
      return render json: {
        content: render_to_string(partial: 'pm/mailderpy'), pages: 0, page: 0
      }
    end
    render_pagination 'pm/thumb', @results
  end
  
  def tab
    @type = params[:type]
    @results = Pagination.paginate(page_for_type(@type), params[:page], 50, false)
    render json: {
      content: render_to_string(partial: 'pm/list_group', locals: { type: @type, paginated: @results, selected: true })
    }
  end
  
  def mark_read
    if user_signed_in? && (pm = Pm.find_for_user(params[:id], current_user))
      pm.unread = !pm.unread
      pm.save
      render json: {
        added: pm.unread
      }
    end
  end
  
  def destroy
    if user_signed_in? && (pm = Pm.find_for_user(params[:id], current_user))
      pm.toggle_deleted
      @page = params[:page].to_i
      @type = params[:type]
      @results = Pagination.paginate(page_for_type(@type), @page, 50, false)
      if @results.count == 0
        return render json: {
          content: render_to_string(partial: 'pm/mailderpy'),
          pages: 0,
          page: 0
        }
      end
      render_pagination 'pm/thumb', @results
    end
    head 403
  end
end

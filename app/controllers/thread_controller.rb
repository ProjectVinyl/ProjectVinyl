class ThreadController < ApplicationController
  def view
    if !(@thread = CommentThread.where('id = ? AND (owner_type = "Board" OR owner_type = "Video")', params[:id]).first)
      return render_error(
        title: 'Nothing to see here!',
        description: "Either the thread does not exist or you don't have the neccessary permissions to see it."
      )
    end
    @order = '0'
    @modifications_allowed = user_signed_in? && (current_user.id == @thread.user_id || current_user.is_contributor?)
    @comments = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_contributor?), (params[:page] || -1).to_i, 10, false)
  end

  def new
    @thread = CommentThread.new
    if params[:user] && @user = User.where(id: params[:user]).first
      return render partial: 'pm/new'
    end
    @thread.owner_id = (params[:board] || 0).to_i
    render partial: 'new'
  end

  def create
    if user_signed_in?
      thread = CommentThread.create(user_id: current_user.id, total_comments: 1, owner_type: 'Board', owner_id: params[:thread][:owner_id])
      thread.set_title(params[:thread][:title])
      thread.save
      comment = thread.comments.create(user_id: current_user.id)
      comment.update_comment(params[:thread][:description])
      thread.subscribe(current_user) if current_user.subscribe_on_thread?
      return redirect_to action: 'view', id: thread.id
    end
    redirect_to action: "index", controller: "welcome"
  end

  def update
    if user_signed_in? && thread = CommentThread.where(id: params[:id]).first
      if thread.user_id == current_user.id || current_user.is_contributor?
        value = ApplicationHelper.demotify(params[:value])
        if params[:field] == 'title'
          thread.set_title(value)
          thread.save
        end
        return head :ok
      end
    end
    head 401
  end
  
  def page
    if !(board = Board.where(id: params[:id]).first)
      return head 404
    end
    render_pagination 'thread/thumb', board.threads, params[:page].to_i, 50, false
  end
  
  def subscribe
    if !user_signed_in? || !(thread = CommentThread.where(id: params[:id]).first)
      head 401
    end
    
    return render json: {
      added: thread.toggle_subscribe(current_user)
    }
  end
end

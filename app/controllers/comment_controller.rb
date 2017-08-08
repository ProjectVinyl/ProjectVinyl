class CommentController < ApplicationController
  def page
    @thread = CommentThread.where(id: params[:thread_id]).first
    if params[:comment] && (@comment = Comment.where(comment_thread_id: @thread.id, id: Comment.decode_open_id(params[:comment])).first)
      @page = @comment.page(:id, 10, params[:order] == '1')
    else
      @page = params[:page].to_i
    end
    @results = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_contributor?), @page, 10, params[:order] == '1')
    
    render_pagination 'comment/set', @results, {
      thread: @results.records,
      indirect: false
    }
  end
  
  def create
    if !user_signed_in? || !(@thread = CommentThread.where(id: params[:thread]).first) || @thread.locked
      return head 401
    end
    
    comment = @thread.comments.create({
      user_id: current_user.id,
      o_comment_thread_id: @thread.id
    })
    @thread.total_comments = @thread.comments.count
    @thread.save
    comment.update_comment(params[:comment])
    
    if @thread.owner_type == 'Video'
      @thread.owner.compute_hotness.save
    end
    
    @results = Pagination.paginate(@thread.get_comments(current_user.is_contributor?), params[:order] == '1' ? 0 : -1, 10, params[:order] == '1')
    @thread.bump(current_user, params, comment)
    render json: {
      content: render_to_string(partial: 'comment/set', locals: {
        thread: @results.records, indirect: false
      }),
      pages: @results.pages,
      page: @results.page,
      focus: comment.get_open_id
    }
  end
  
  def update
    if !user_signed_in? || !(comment = Comment.where(id: params[:id]).first)
      return head 401
    end
    
    comment.update_comment(params[:comment])
    head :ok
  end
  
  def like
    if !user_signed_in? || !(comment = Comment.where(id: params[:id]).first)
      return head 401
    end
    
    render json: {
      added: comment.upvote(current_user, params[:incr])
    }
  end
  
  def destroy
    if !user_signed_in?
      return head 401
    end
    
    if !(comment = Comment.where(id: params[:id]).first)
      return head 404
    end
    
    if !current_user.is_contributor? && current_user.id != comment.user_id
      return head 401
    end
    
    CommentThread.where(id: comment.comment_thread_id).update_all("total_comments = total_comments #{comment.hidden ? '+' : '-'} 1")
    comment.hidden = !comment.hidden
    comment.save
    
    if !comment.hidden || current_user.is_contributor?
      return render json: {
        message: "success",
        content: render_to_string(partial: 'comment/comment', locals: {
          comment: comment,
          indirect: !params[:indirect].nil?
        })
      }
    end
    
    render json: {
      message: "success",
      reload: true
    }
  end
end

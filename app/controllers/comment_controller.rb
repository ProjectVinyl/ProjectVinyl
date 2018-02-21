class CommentController < ApplicationController
  def page
    @thread = CommentThread.where(id: params[:thread_id]).first
    
    if params[:comment] && (@comment = Comment.where(comment_thread_id: @thread.id, id: Comment.decode_open_id(params[:comment])).first)
      @page = @comment.page(:id, 10, params[:order] == '1')
    else
      @page = params[:page].to_i
    end
    
    @records = @thread.get_comments(user_signed_in? && current_user.is_contributor?).with_likes(current_user)
    render_pagination 'comment/comment', @records, @page, 10, params[:order] == '1', {
      indirect: false
    }
  end
  
  def create
    if !(@thread = CommentThread.where(id: params[:thread]).first) || @thread.locked
      return head :not_found
    end
    
    user = user_signed_in? ? current_user : UserAnon.new(session)
    
    if !user_signed_in?
      if !verify_recaptcha(model: user)
        return render json: { error: user.error }
      end
    end
    
    comment = @thread.comments.create(
      user_id: user_signed_in? ? current_user.id : UserAnon.anon_id(session),
      o_comment_thread_id: @thread.id
    )
    @thread.total_comments = @thread.comments.count
    @thread.save
    comment.update_comment(params[:comment])
    
    if @thread.owner_type == 'Video'
      @thread.owner.compute_hotness.save
    end
    
    @thread.bump(user, params, comment)
    
    @reverse = params[:order] == '1'
    @records = @thread.get_comments(user_signed_in? && current_user.is_contributor?).with_likes(current_user)
    @records = Pagination.paginate(@records, @reverse ? 0 : -1, 10, @reverse)
    
    @json = pagination_json_for_render 'comment/comment', @records, {
      indirect: false
    }
    @json[:focus] = comment.get_open_id
    render json: @json
  end
  
  def update
    check_then do |comment|
      render json: {
				content: comment.update_comment(params[:comment])
      }
    end
  end
  
  def like
    check_then do |comment|
      render json: {
        count: comment.upvote(current_user, params[:incr])
      }
    end
  end
  
  def destroy
    check_then do |comment|
      if !current_user.is_contributor? && current_user.id != comment.user_id
        return head 401
      end
      
      CommentThread.where(id: comment.comment_thread_id).update_all("total_comments = total_comments #{comment.hidden ? '+' : '-'} 1")
      comment.hidden = !comment.hidden
      comment.save
      
      if comment.hidden && !current_user.is_contributor?
        return render json: {
          message: "success",
          reload: true
        }
      end
      
      render json: {
        message: "success",
        content: render_to_string(partial: 'comment/comment', locals: {
          comment: comment,
          indirect: !params[:indirect].nil?
        })
      }
    end
  end
  
  
  private
  def check_then
    if !user_signed_in?
      return head 401
    end
    
    if !(comment = Comment.where(id: params[:id]).first)
      return head :not_found
    end
    
    yield(comment)
  end
end

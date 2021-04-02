class CommentsController < Comments::BaseCommentsController
  def create
    return head :not_found if !(@thread = CommentThread.where(id: params[:thread_id]).first) || @thread.locked

    user = user_signed_in? ? current_user : UserAnon.new(session)
    
    if !user_signed_in?
      return render json: { error: "BG Ponies are disabled" } if !ApplicationHelper.bg_ponies
      return render json: { error: user.error } if !verify_recaptcha(model: user)
    end
    
    comment = @thread.comments.create(
      user_id: anonymous_user_id,
      o_comment_thread_id: @thread.id,
      anonymous_id: params[:anonymous] == '1' ? UserAnon.anon_id(session) : 0
    )

    @thread.total_comments = @thread.comments.count
    @thread.save
    comment.update_comment(params[:comment])
    
    @thread.owner.compute_hotness.save if @thread.owner_type == 'Video'
    @thread.bump(user, params, comment)
    
    @reverse = params[:order] == '1'
    @records = @thread.get_comments(current_user).with_likes(current_user)
    @records = Pagination.paginate(@records, @reverse ? 0 : -1, 10, @reverse)
    
    @json = pagination_json_for_render @records, partial: 'comments/comment', indirect: false
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

  def destroy
    check_then do |comment|
      return head 401 if !current_user.is_contributor? && current_user.id != comment.user_id

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
        content: render_to_string(partial: 'comments/comment', locals: {
          comment: comment,
          indirect: params[:indirect] == 'true'
        })
      }
    end
  end
end

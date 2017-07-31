class CommentController < ApplicationController
  def page
    @thread = CommentThread.where(id: params[:thread_id]).first
    if params[:comment] && (@comment = Comment.where(comment_thread_id: @thread.id, id: Comment.decode_open_id(params[:comment])).first)
      @page = @comment.page(:id, 10, params[:order] == '1')
    else
      @page = params[:page].to_i
    end
    @results = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_contributor?), @page, 10, params[:order] == '1')
    render json: {
      content: render_to_string(partial: 'comment/set.html.erb', locals: { thread: @results.records, indirect: false }),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def create
    if user_signed_in?
      if (@thread = CommentThread.where(id: params[:thread]).first) && !@thread.locked
        comment = @thread.comments.create(user_id: current_user.id, o_comment_thread_id: @thread.id)
        @thread.total_comments = @thread.comments.count
        @thread.save
        comment.update_comment(params[:comment])

        @thread.owner.compute_hotness.save if @thread.owner_type == 'Video'

        @results = Pagination.paginate(@thread.get_comments(current_user.is_contributor?), params[:order] == '1' ? 0 : -1, 10, params[:order] == '1')
        render json: {
          content: render_to_string(partial: 'comment/set.html.erb', locals: { thread: @results.records, indirect: false }),
          pages: @results.pages,
          page: @results.page,
          focus: comment.get_open_id
        }
        return @thread.bump(current_user, params, comment)
      end
    end
    head 401
  end
  
  def update
    if user_signed_in? && (comment = Comment.where(id: params[:id]).first)
      comment.update_comment(params[:comment])
      head :ok
      return
    end
    head 401
  end
  
  def like
    if user_signed_in?
      if comment = Comment.where(id: params[:id]).first
        return render json: { added: comment.upvote(current_user, params[:incr]) }
      end
    end
    head 401
  end
  
  def destroy
    if user_signed_in? && comment = Comment.where(id: params[:id]).first
      if current_user.is_contributor? || current_user.id == comment.user_id
        if comment.hidden && current_user.is_contributor?
          comment.hidden = false
          CommentThread.where(id: comment.comment_thread_id).update_all('total_comments = total_comments + 1')
          comment.save
          render json: {
            message: "success",
            content: render_to_string(partial: 'comment/comment.html.erb', locals: { comment: comment, indirect: !params[:indirect].nil? })
          }
        else
          comment.hidden = true
          CommentThread.where(id: comment.comment_thread_id).update_all('total_comments = total_comments - 1')
          comment.save
          if current_user.is_contributor?
            render json: {
              message: "success",
              content: render_to_string(partial: 'comment/comment.html.erb', locals: { comment: comment, indirect: !params[:indirect].nil? })
            }
          else
            render json: {
              message: "success", reload: true
            }
          end
        end
        return
      end
    end
    head 401
  end
end

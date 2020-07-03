module Forum
  class ThreadsController < ApplicationController
    def show
      @thread = CommentThread.where(id: params[:thread_id] || params[:id]).first
      
      if !@thread || !@thread.contributing?(current_user)
        return render_error(
          title: 'Nothing to see here!',
          description: "Either the thread does not exist or you don't have the necessary permissions to see it."
        )
      end
      
      if params[:format] != 'json'
        if @thread.private_message?
          return redirect_to action: :show, controller: "inbox/pm", id: @thread.owner_id
        elsif @thread.video?
          return redirect_to action: :show, controller: "/videos", id: @thread.owner_id
        end
      end
      
      if params[:comment] && (@comment = Comment.where(comment_thread_id: @thread.id, id: Comment.decode_open_id(params[:comment])).first)
        @page = @comment.page(:id, 10, params[:order] == '1')
      else
        @page = params[:page].to_i
      end
      
      @order = params[:order] == '1'
      @modifications_allowed = user_signed_in? && (current_user.id == @thread.user_id || current_user.is_contributor?)
      @comments = Pagination.paginate(
        @thread.get_comments(current_user)
               .with_likes(current_user),
        @page, 10, @order)
      
      if params[:format] == 'json'
        render_pagination_json 'comments/comment', @comments, {
          indirect: false
        }
      end
    end
    
    def new
      @thread = CommentThread.new
      @thread.owner_id = (params[:board] || 0).to_i
      render partial: 'new'
    end

    def create
      if user_signed_in?
        thread = CommentThread.create(
          user_id: current_user.id,
          total_comments: 1,
          owner_type: 'Board',
          owner_id: params[:thread][:owner_id]
        )
        thread.set_title(params[:thread][:title])
        thread.save
        comment = thread.comments.create(user_id: current_user.id)
        comment.update_comment(params[:thread][:description])
        if current_user.subscribe_on_thread?
          thread.subscribe(current_user)
        end
        return redirect_to action: :show, id: thread.id
      end
      redirect_to action: :index, controller: :welcome
    end

    def update
      if !user_signed_in?
        return head 401
      end
      
      if !(thread = CommentThread.where(id: params[:id]).first)
        return head :not_found
      end
      
      if !(thread.user_id == current_user.id || current_user.is_contributor?)
        return head 401
      end
      
      if params[:field] == 'title'
        thread.set_title(params[:value])
        thread.save
        render json: { content: thread.title }
      end
    end
  end
end

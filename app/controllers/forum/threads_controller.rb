module Forum
  class ThreadsController < ApplicationController
    def show
      @path_type = 'forum'
      @thread = CommentThread.where(id: params[:thread_id] || params[:id]).first
      
      if !@thread || !@thread.contributing?(current_user)
        return render_error(
          title: 'Nothing to see here!',
          description: "Either the thread does not exist or you don't have the necessary permissions to see it."
        )
      end
      
      if params[:format] != 'json'
        return redirect_to action: :show, controller: "inbox/pm", id: @thread.owner_id if @thread.private_message?
        return redirect_to action: :show, controller: "/videos", id: @thread.owner_id if @thread.video?
      end
      
      if params[:comment] && (@comment = Comment.where(comment_thread_id: @thread.id, id: Comment.decode_open_id(params[:comment])).first)
        @page = @comment.page(:id, 10, params[:order] == '1')
      else
        @page = params[:page].to_i
      end
      
      @order = params[:order] == '1'
      @modifications_allowed = user_signed_in? && (current_user.id == @thread.user_id || current_user.is_contributor?)
      @comments = @thread.pagination(current_user, page: @page, reverse: @order)

      return render_empty_pagination 'comments/empty_set' if params[:format] == 'json' && @comments.count == 0
      render_paginated @comments, partial: 'comments/comment', as: :json, indirect: false if params[:format] == 'json'
    end
    
    def new
      @thread = CommentThread.new
      @thread.owner_id = (params[:board] || 0).to_i
      render partial: 'new'
    end

    def create
      if user_signed_in?
        thread = CommentThread.create(
          title: params[:thread][:title],
          user_id: current_user.id,
          total_comments: 1,
          owner_type: 'Board',
          owner_id: params[:thread][:owner_id]
        )
        comment = thread.comments.create(user_id: current_user.id, bbc_content: params[:thread][:description])
        thread.subscribe(current_user) if current_user.subscribe_on_thread?

        return redirect_to action: :show, id: thread.id
      end
      redirect_to action: :index, controller: :welcome
    end

    def update
      return head 401 if !user_signed_in?
      return head :not_found if !(thread = CommentThread.where(id: params[:id]).first)
      return head 401 if !(thread.user_id == current_user.id || current_user.is_contributor?)

      if params[:field] == 'title'
        thread.title = params[:value]
        thread.save
        render json: { content: thread.title }
      end
    end
  end
end

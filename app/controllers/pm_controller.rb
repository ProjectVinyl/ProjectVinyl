class PmController < ApplicationController
  def view
    if !(user_signed_in? && @pm = Pm.find_for_user(params[:id], current_user))
      return render '/layouts/error', locals: { title: 'Nothing to see here!', description: "Either the thread does not exist or you don't have the neccessary permissions to see it." }
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

  def list
    @page = params[:page].to_i
    @type = params[:type] || 'new'
    @result = Pagination.paginate(page_for_type(@type), @page, 50, false)
    if @type == 'new'
      @new = @result.count
    else
      @new = page_for_type('new').count
    end
  end

  def page_for_type(type)
    Pm.find_for_tab(type, current_user)
  end

  def page_threads
    @page = params[:page].to_i
    @results = Pagination.paginate(page_for_type(params[:type]), @page, 50, false)
    if @results.count == 0
      return render json: {
        content: render_to_string(partial: '/pm/mailderpy.html.erb'), pages: 0, page: 0
      }
    end
    render json: {
      content: render_to_string(partial: '/pm/message_thumb.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end

  def page
    @thread = CommentThread.where(id: params[:thread_id]).first
    if params[:comment] && (@comment = Comment.where(comment_thread_id: @thread.id, id: Comment.decode_open_id(params[:comment])).first)
      @page = @comment.page(:id, 10, params[:order] == '1')
    else
      @page = params[:page].to_i
    end
    @results = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_contributor?), @page, 10, params[:order] == '1')
    render json: {
      content: render_to_string(partial: '/thread/comment_set.html.erb', locals: { thread: @results.records, indirect: false }),
      pages: @results.pages,
      page: @results.page
    }
  end

  def tab
    @type = params[:type]
    @results = Pagination.paginate(page_for_type(@type), params[:page], 50, false)
    render json: {
      content: render_to_string(partial: '/pm/list_group.html.erb', locals: { type: @type, paginated: @results, selected: true })
    }
  end

  def delete_pm
    if user_signed_in? && (pm = Pm.find_for_user(params[:id], current_user))
      pm.toggle_deleted
      @page = params[:page].to_i
      @type = params[:type]
      @results = Pagination.paginate(page_for_type(@type), @page, 50, false)
      if @results.count == 0
        return render json: {
          content: render_to_string(partial: '/pm/mailderpy.html.erb'), pages: 0, page: 0
        }
      end
      return render json: {
        content: render_to_string(partial: '/pm/message_thumb.html.erb', collection: @results.records),
        pages: @results.pages,
        page: @results.page
      }
    end
    render status: 402, nothing: true
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
end

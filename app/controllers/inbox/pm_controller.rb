module Inbox
  class PmController < BaseInboxController
    before_action :check_requirements, only: [:destroy]

    def show
      if !(user_signed_in? && @pm = Pm.find_for_user(params[:id], current_user))
        return render_error(
          title: 'Nothing to see here!',
          description: "Either the thread does not exist or you don't have the necessary permissions to see it."
        )
      end

      @order = params[:order].to_i
      @thread = @pm.comment_thread
      @comments = @thread.pagination(current_user, page: (params[:page] || -1).to_i, reverse: @order == 1)
      @crumb = {
        stack: [
          { link: "/inbox", title: "Private Messages" }
        ],
        title: @thread.title
      }
      if @pm.unread
        @pm.unread = false
        @pm.save
      end
    end

    def new
      @thread = CommentThread.new
      @user = User.where(id: params[:user]).first if params[:user]
      render partial: 'new'
    end

    def create
      return redirect_to action: :index, controller: :welcome if !user_signed_in?

      recipients = User.as_recipients(params[:thread][:recipient])

      return redirect_to action: :index, controller: :welcome if recipients.length == 0

      redirect_to action: :show, id: Pm.send_pm(current_user, recipients, params[:thread][:title], params[:thread][:description]).id
    end

    def destroy
      @order = params[:order].to_i
      @pm.toggle_deleted

      @type = params[:type]
      @results = paginate_for_type(@type)

      @json = pagination_json_for_render @results, partial: 'inbox/pm/thumb'
      @json[:tabs] = tab_changes
      render json: @json
    end
  end
end
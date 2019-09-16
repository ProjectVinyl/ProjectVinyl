module Tags
  class ChangesController < ApplicationController
    def index
      name = params[:tag_id].downcase
      if !(@tag = Tag.by_name_or_id(name).first)
        return render_error(
          title: 'Nothing to see here but us Fish!',
          description: 'This tag does not exist.'
        )
      end

      if @tag.alias_id
        flash[:notice] = "The tag '#{@tag.name}' has been aliased to '#{@tag.alias.name}'"
        if !user_signed_in? || !current_user.is_staff?
          return redirect_to action: :view, name: @tag.alias.short_name
        end
      end

      @history = @tag.tag_histories.includes(:tag, :user).order(:created_at)

      if params[:added]
        @history = @history.where(added: params[:added].to_i == 1)
      else
        @history = @history.where.not(added: nil)
      end

      @history = Pagination.paginate(@history, params[:page].to_i, 20, true)

      if params[:format] == 'json'
        if @history.count == 0
          return render_empty_pagination 'wardenderpy'
        end
        render_pagination_json 'change', @history
      end

      @crumb = {
        stack: [
          { title: 'Tags' },
          { link: @tag.link, title: @tag.name }
        ],
        title: "Tag Changes"
      }
    end
  end
end
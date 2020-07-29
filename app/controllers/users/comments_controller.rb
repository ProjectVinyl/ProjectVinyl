module Users
  class CommentsController < Users::BaseUsersController
    def index
      check_details_then do |user, edits_allowed|
        @records = user.comments.visible.decorated.with_likes(current_user).order(:created_at)

        @records = Pagination.paginate(@records, params[:page].to_i, 50, true)

        @label = 'Comments'
        @table = 'Comment'
        @partial = partial_for_type(@label)

        return render_pagination_json @partial, @records if params[:format] == 'json'

        @crumb = {
          stack: [
            { link: '/users', title: 'Users' },
            { link: @user.link, title: @user.username }
          ],
          title: @label
        }

        render template: 'users/comments'
      end
    end
  end
end

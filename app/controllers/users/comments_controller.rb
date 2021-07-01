module Users
  class CommentsController < Users::BaseUsersController
    def index
      check_details_then do |user, edits_allowed|
        @records = user.comments.visible.decorated.with_owner.with_likes(current_user).order(:created_at)
        @records = @records.where(anonymous_id: 0) if !edits_allowed
        @records = Pagination.paginate(@records, params[:page].to_i, 50, true)

        @label = 'Comments'
        @table = 'Comment'
        @partial = partial_for_type(@label)

        return render_paginated @records, partial: @partial, as: :json if params[:format] == 'json'

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

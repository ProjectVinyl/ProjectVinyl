module Users
  class WatchHistoryController < Users::BaseUsersController
    before_action :authenticate_user!

    def index
      check_details_then do |user, edits_allowed|
        return render_access_denied if user.id != current_user.id && !current_user.is_contributor?
        
        @records = user.watched_videos.unmerged.listable
        @records = @records.where(listing: 0) if !edits_allowed
        @records = Pagination.paginate(@records, params[:page].to_i, 50, params[:order].to_i == 1)

        @label = 'Watch History'
        @table = 'watch_history'
        @partial = partial_for_type(:videos)

        return render_paginated @records, partial: @partial, as: :json if params[:format] == 'json'

        @crumb = {
          stack: [
            { link: '/users', title: 'Users' },
            { link: @user.link, title: @user.username }
          ],
          title: @label
        }

        render template: 'users/listing'
      end
    end
  end
end

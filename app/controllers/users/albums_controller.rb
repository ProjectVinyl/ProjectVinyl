module Users
  class AlbumsController < Users::BaseUsersController
    def index
      check_details_then do |user, edits_allowed|
        @records = user.albums.order(:created_at).where(hidden: false)
        if !edits_allowed
          @records = @records.where(listing: 0)
        end
        
        @records = Pagination.paginate(@records, params[:page].to_i, 50, true)
        
        @label = 'Albums'
        @table = 'Album'
        @partial = partial_for_type(:albums)
        
        if params[:format] == 'json'
          return render_pagination_json @partial, @records
        end
        
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

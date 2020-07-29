module Users
  class UploadsController < BaseUsersController
    def index
      check_details_then do |user, edits_allowed|
        @records = user.videos.order(:created_at).includes(:tags).where(duplicate_id: 0)
        @records = @records.listable if !edits_allowed
        @records = Pagination.paginate(@records, params[:page].to_i, 50, true)
        
        @label = 'Uploads'
        @table = 'Video'
        @partial = partial_for_type(:videos)
        
        return render_pagination_json @partial, @records if params[:format] == 'json'
        render template: 'users/listing'
      end
    end
  end
end

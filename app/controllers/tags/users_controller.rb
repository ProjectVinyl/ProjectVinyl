module Tags
  class UsersController < ApplicationController
    def index
      if !(@tag = Tag.where(id: params[:tag_id]).first)
        return head :not_found
      end
      @records = @tag.users.order(:updated_at)
      render_pagination 'users/thumb_h', @records, params[:page].to_i, 8, true
    end
  end
end

module Tags
  class UsersController < ApplicationController
    def index
      return head :not_found if !(@tag = Tag.where(id: params[:tag_id]).first)
      @records = @tag.users.order(:updated_at)
      render_pagination partial_for_type(:users), @records, params[:page].to_i, 8, true
    end
  end
end

module Users
  class HovercardsController < BaseUsersController
    def show
      if !(user = User.with_badges.where(id: params[:user_id]).first)
        return head :not_found
      end
      
      render partial: 'users/thumb_h', locals: {thumb_h: user}
    end
  end
end

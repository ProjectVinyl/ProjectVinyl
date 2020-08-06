module Users
  class HovercardsController < BaseUsersController
    def show
      return head :not_found if !(user = User.with_badges.where(id: params[:user_id]).first)
      render partial: partial_for_type(:users), locals: {normal: user}
    end
  end
end

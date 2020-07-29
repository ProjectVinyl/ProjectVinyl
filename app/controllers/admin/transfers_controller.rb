module Admin
  class TransfersController < BaseAdminController
    def update
      return head :unauthorized if !current_user.is_contributor?

      if ['video','album'].includes?(params[:type])
        item = params[:type].titlecase.constantize.where(id: params[:item][:id]).first
      end

      return head :not_found if !item

      redirect_to action: :show, controller: '/admin/' + params[:type].pluralize, id: params[:item][:id]

      if !(user = User.by_name_or_id(params[:item][:user_id]))
        return flash[:alert] = "Error: Destination user was not found."
      end

      item.transfer_to(user)
    end
  end
end

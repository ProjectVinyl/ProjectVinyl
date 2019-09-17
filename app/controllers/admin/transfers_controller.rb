module Admin
  class TransfersController < BaseAdminController
    def update
      if !current_user.is_contributor?
        return head :unauthorized
      end
      
      if params[:type] == 'video'
        item = Video.where(id: params[:item][:id]).first
      elsif params[:type] == 'album'
        item = Album.where(id: params[:item][:id]).first
      end
      
      if !item
        return head :not_found
      end
      
      redirect_to action: :show, controller: '/admin/' + params[:type].pluralize, id: params[:item][:id]
      
      if !(user = User.by_name_or_id(params[:item][:user_id]))
        return flash[:alert] = "Error: Destination user was not found."
      end
      
      item.transfer_to(user)
    end
  end
end

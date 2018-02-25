module Admin
  class AdminController < ApplicationController
    before_action :authenticate_user!

    def view
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      @hiddenvideos = Pagination.paginate(Video.where(hidden: true).with_likes(current_user), params[:hidden].to_i, 40, true)
      @unprocessed = Pagination.paginate(Video.where("(processed IS NULL or processed = ?) AND hidden = false", false).with_likes(current_user), params[:unprocessed].to_i, 40, false)
      @users = User.where('last_sign_in_at > ? OR updated_at > ?', Time.zone.now.beginning_of_month, Time.zone.now.beginning_of_month).limit(100).order(:last_sign_in_at).reverse_order
      @reports = Pagination.paginate(Report.includes(:reportable).open, params[:reports].to_i, 40, false)
    end
    
    def transfer
      if !current_user.is_contributor?
        return head 401
      end
      
      if params[:type] == 'video'
        item = Video.where(id: params[:item][:id]).first
      elsif params[:type] == 'album'
        item = Album.where(id: params[:item][:id]).first
      end
      
      if !item
        return head :not_found
      end
      
      redirect_to action: params[:type], id: params[:item][:id]
      
      if !(user = User.by_name_or_id(params[:item][:user_id]))
        return flash[:alert] = "Error: Destination user was not found."
      end
      
      item.transfer_to(user)
    end
    
    def reindex
      if !current_user.is_contributor?
        flash[:notice] = "Access Denied: You do not have the required permissions."
        return redirect_to action: "view"
      end
      
      if !(table = params[:table] == 'user' ? User : params[:table] == 'video' ? Video : nil)
        flash[:notice] = "Error: Table #{params[:table]} was not found."
        return redirect_to action: "view"
      end
      
      if params[params[:table]]
        if !(table = table.where(id: params[params[:table]][:id]).first)
          flash[:notice] = "Error: Record #{params[:table]}.#{params[params[:table]][:id]} was not found."
          return redirect_to action: "view"
        end
        
        table.update_index(defer: false)
        flash[:notice] = "Success! Indexes for record #{params[:table]}.#{params[params[:table]][:id]} have been completed."
        return redirect_to action: 'view', controller: 'admin/' + params[:table], id: params[params[:table]][:id]
      end
      
      RecreateIndexJob.perform_later(current_user.id, table.to_s)
      flash[:notice] = "Success! Indexes for table #{params[:table]} has been scheduled. Check back later for a completion report."
    end
    
    def verify
      redirect_to url_for(action: 'view')
      
      if !current_user.is_admin?
        return flash[:notice] = "Access Denied: You do not have the required permissions."
      end
      
      VerificationJob.perform_later(current_user.id)
      flash[:notice] = "Success! An integrity check has been launched. A report will be generated upon completion."
    end
  end
end

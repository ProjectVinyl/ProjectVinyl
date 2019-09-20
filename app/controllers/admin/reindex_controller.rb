module Admin
  class ReindexController < BaseAdminController
    def update
      if !current_user.is_contributor?
        flash[:notice] = "Access Denied: You do not have the required permissions."
        return redirect_to action: "view"
      end
      
      if !(table = params[:id] == 'users' ? User : params[:id] == 'videos' ? Video : nil)
        flash[:notice] = "Error: Table #{params[:id]} was not found."
        return redirect_to action: "view"
      end
      
      if params[params[:id]]
        if !(table = table.where(id: params[params[:id]][:id]).first)
          flash[:notice] = "Error: Record #{params[:id]}.#{params[params[:id]][:id]} was not found."
          return redirect_to action: "view"
        end
        
        table.update_index(defer: false)
        flash[:notice] = "Success! Indexes for record #{params[:id]}.#{params[params[:id]][:id]} have been completed."

        return redirect_to action: :show, controller: 'admin/' + params[:id], id: params[params[:id]][:id]
      end
      
      begin
        RecreateIndexJob.perform_later(current_user.id, table.to_s)
        flash[:notice] = "Success! Indexes for table #{params[:id]} has been scheduled. Check back later for a completion report."
      rescue
        flash[:notice] = "Error: Elasti-search does not appear to be running."
      end

      return redirect_to action: :index, controller: 'admin/admin'
    end
  end
end

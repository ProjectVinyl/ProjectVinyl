module Admin
  class AdminController < ApplicationController
    before_action :authenticate_user!

    def view
      if !user_signed_in? || !current_user.is_contributor?
        return render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      end
      @hiddenvideos = Pagination.paginate(Video.where(hidden: true), params[:hidden].to_i, 40, true)
      @unprocessed = Pagination.paginate(Video.where("(processed IS NULL or processed = ?) AND hidden = false", false), params[:unprocessed].to_i, 40, false)
      @users = User.where('last_sign_in_at > ? OR updated_at > ?', Time.zone.now.beginning_of_month, Time.zone.now.beginning_of_month).limit(100).order(:last_sign_in_at).reverse_order
      @reports = Pagination.paginate(Report.includes(:video).where(resolved: nil), params[:reports].to_i, 40, false)
    end
    
    def transfer_item
      if user_signed_in? && current_user.is_contributor?
        if (user = User.by_name_or_id(params[:item][:user_id]))
          if params[:type] == 'video'
            item = Video.where(id: params[:item][:id]).first
          elsif params[:type] == 'album'
            item = Album.where(id: params[:item][:id]).first
          end
          if item
            item.transfer_to(user)
            return redirect_to action: params[:type], id: params[:item][:id]
          end
        else
          flash[:alert] = "Error: Destination user was not found."
          return redirect_to action: params[:type], id: params[:item][:id]
        end
      end
      head 401
    end
    
    def reindex
      if user_signed_in? && current_user.is_contributor?
        if table = params[:table] == 'user' ? User : params[:table] == 'video' ? Video : nil
          if params[params[:table]]
            if table = table.where(id: params[params[:table]][:id]).first
              table.update_index(defer: false)
              flash[:notice] = "Success! Indexes for record #{params[:table]}.#{params[params[:table]][:id]} have been completed."
              return redirect_to action: params[:table], id: params[params[:table]][:id]
            else
              flash[:notice] = "Error: Record #{params[:table]}.#{params[params[:table]][:id]} was not found."
              return render status: 404, json: { ref: url_for(action: "view") }
            end
          else
            RecreateIndexJob.perform_later(current_user.id, table.to_s)
            flash[:notice] = "Success! Indexes for table #{params[:table]} has been scheduled. Check back later for a completion report."
          end
        else
          flash[:notice] = "Error: Table #{params[:table]} was not found."
        end
      else
        flash[:notice] = "Access Denied: You do not have the required permissions."
      end
      render json: { ref: url_for(action: "view") }
    end
    
    def verify_integrity
      if user_signed_in? && current_user.is_admin?
        VerificationJob.perform_later(current_user.id)
        flash[:notice] = "Success! An integrity check has been launched. A report will be generated upon completion."
      else
        flash[:notice] = "Access Denied: You do not have the required permissions."
      end
      redirect_to url_for(action: 'view')
    end
  end
end

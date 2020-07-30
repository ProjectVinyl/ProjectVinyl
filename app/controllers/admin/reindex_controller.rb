module Admin
  class ReindexController < BaseAdminController
    INDEXABLE_TABLES = [:videos, :tags, :users].freeze

    def update
      return fail_fast "Access Denied: You do not have the required permissions." if !current_user.is_contributor?
      
      key = params[:id]
      table_sym = (key || '').downcase.to_sym
      
      return fail_fast "Error: Operation not supported." if !INDEXABLE_TABLES.includes?(table_sym)
      return fail_fast "Error: Table #{table_sym} was not found or does not support that action." if !(table = table_sym.to_s.titlecase.constantize)

      if (record = params[key])
        id = record[:id]

        return fail_fast "Error: Record #{table_sym}.#{id} was not found." if !(model = model.where(id: id).first)
        
        model.update_index(defer: false)
        flash[:notice] = "Success! Indexing for record #{table_sym}.#{id} have been completed."
        return redirect_to action: :show, controller: "admin/#{table_sym}", id: id
      end
      
      begin
        RecreateIndexJob.perform_later(current_user.id, table.to_s)
        flash[:notice] = "Success! Indexes for table #{table_sym} has been scheduled. Check back later for a completion report."
      rescue
        flash[:notice] = "Error: Elasticsearch does not appear to be running."
      end

      return redirect_to action: :index, controller: 'admin/admin'
    end
    
    private
    def fail_fast(msg)
      flash[:notice] = msg
      redirect_to action: "view"
    end
  end
end

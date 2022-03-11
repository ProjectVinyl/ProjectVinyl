module Admin
  module Search
    class ReindexController < BaseAdminController
      INDEXABLE_TABLES = [:video, :tag, :user].freeze

      def update
        bounce_back
        return flash[:error] = "Access Denied: You do not have the required permissions." if !current_user.is_contributor?

        key = params[:id]
        table_sym = (key || '').downcase.to_sym

        return flash[:error] = "Error: Operation not supported." if !INDEXABLE_TABLES.include?(table_sym)
        return flash[:error] = "Error: Table #{table_sym} was not found or does not support that action." if !(@table = table_sym.to_s.titlecase.constantize)

        if (record = params[key])
          id = record[:id]

          return flash[:error] = "Error: Record #{table_sym}.#{id} was not found." if !(@model = @table.where(id: id).first)

          @model.update_index(defer: true)
          return flash[:notice] = "Success! Indexing for record #{table_sym}.#{id} have been scheduled.."
        end

        RefreshIndexJob.perform_later(current_user.id, @table.to_s)
        flash[:notice] = "Success! Indexing for table #{table_sym} has been scheduled. Check back later for a completion report."
      end
    end
  end
end

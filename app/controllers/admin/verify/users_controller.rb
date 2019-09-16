module Admin
  module Verify
    class UsersController < BaseAdminController

      def update
        redirect_to url_for(controller: '/admin/admin', action: 'view')

        if !current_user.is_admin?
          return flash[:notice] = "Access Denied: You do not have the required permissions."
        end

        UserVerificationJob.perform_later(current_user.id)
        flash[:notice] = "Success! An integrity check has been launched. A report will be generated upon completion."
      end
    end
  end
end

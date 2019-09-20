module Inbox
  class BaseInboxController < ApplicationController

    protected
    def check_requirements
      if !user_signed_in?
        return head :unauthorized
      end

      if !(@pm = Pm.find_for_user(params[:message_id], current_user))
        return head :not_found
      end
    end

    def tab_changes(type = nil, results = nil)
      {
        new: count_for_type('new')
      }
    end

    def count_for_type(type)
      Pm.find_for_tab_counter(type, current_user).count
    end

    def page_for_type(type)
      Pm.find_for_tab(type, current_user)
    end

    def paginate_for_type(type)
      Pagination.paginate(page_for_type(type), params[:page].to_i, 50, false)
    end
  end
end
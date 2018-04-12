module Admin
  class CommentController < ApplicationController
    def report
      if !(reportable = Comment.where(id: params[:comment_id]))
        return head :not_found
      end
      
      Report.generate_report(
        reportable: reportable,
        user_id: user_signed_in? ? current_user.id : UserAnon.anon_id(session)
      )
    end
  end
end
module Admin
  class ReportController < ApplicationController
    def show
      if !user_signed_in?
        return render_access_denied
      end
      
      if !(@report = Report.where(id: params[:id]).first)
        return render_error(
          title: 'Not Found',
          description: "This is not the report you are looking for."
        )
      end
      
      if !current_user.is_contributor? && current_user.id != @report.user_id
        return render_access_denied
      end
      
      @thread = @report.comment_thread
      @order = '0'
      
      @comments = Pagination.paginate(@thread.get_comments(true), (params[:page] || -1).to_i, 10, false)
      @video = @report.reportable
      @user = @report.user
      
    end
    
    def status
      if !user_signed_in? || !current_user.is_contributor?
        return render_access_denied
      end
      
      if !(@report = Report.where(id: params[:id]).first)
        return head :not_found
      end
      
      @report.bump(current_user, params, nil)
      
      render json: {
        status: @report.status
      }
    end
    
    def index
      if !user_signed_in?
        return head 401
      end
      
      @records = Report.includes(:reportable).open
      render_pagination 'thumb', @records, params[:page].to_i, 40, false
    end
    
    def new
      if !(reportable = Reportable.find(params))
        return head :not_found
      end
      
      render json: {
        content: render_to_string(partial: 'new', locals: {
          reportable: reportable,
          report: Report.new
        })
      }
    end
    
    def create
      
      if !(reportable = Reportable.find(params))
        return head :not_found
      end
      
      reportable.report(anonymous_user_id, params)
      
      head :ok
    end
  end
end

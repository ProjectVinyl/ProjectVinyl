module Admin
  class ReportsController < ApplicationController
    before_action :authenticate_user!, except: [:new, :create]
    
    def show
      if !(@report = Report.where(id: params[:id]).first)
        return render_error(
          title: 'Not Found',
          description: "This is not the report you are looking for."
        )
      end
      
      if !current_user.is_contributor? && current_user.id != @report.user_id
        return render_access_denied
      end
      
      @crumb = {
        stack: [
          { link: "/admin", title: "Admin" }
        ],
        title: "Reports"
      }
      
      @thread = @report.comment_thread
      @order = '0'
      
      @comments = Pagination.paginate(@thread.get_comments(true), (params[:page] || -1).to_i, 10, false)
      @video = @report.reportable
      @user = @report.user
      
    end
    
    def index
      if !user_signed_in?
        if params[:format] == 'json'
          return head :unauthorized
        end
        
        return render_access_denied
      end
      
      if params[:reportable_class] && params[:reportable_id]
        @reportable = Reportable.find(params)
      end
      
      @records = Report.includes(:reportable).open
      
      if @reportable
        @records = @records.where(reportable: @reportable)
      end
      
      render_listing_total @records, params[:page].to_i, 0, true, {
        is_admin: true, table: :reports, label: 'Report', scope: :admin
      }
    end
    
    def update
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      if !(@report = Report.where(id: params[:report_id]).first)
        return head :not_found
      end
      
      render json: {
        status: @report.change_status(current_user, params[:state].to_sym)
      }
    end
    
    def close_all
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      total = Report.open.count
      Report.open.change_status(:close)
      
      flash["success"] = "The status for #{total} reports have been updated to Closed."
      
      redirect_to action: :view, controller: :admin
    end
    
    def new
      if !(@reportable = Reportable.find(params))
        return head :not_found
      end
      
      @report = {
        reportable: @reportable,
        report: Report.new
      }
      
      if params[:format] == 'json'
        render json: {
          content: render_to_string(partial: 'new', locals: @report)
        }
      end
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

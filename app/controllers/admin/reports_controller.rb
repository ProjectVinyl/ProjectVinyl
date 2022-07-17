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
      
      return render_access_denied if !current_user.is_contributor? && current_user.id != @report.user_id

      
      @thread = @report.comment_thread
      @order = '0'
      @comments = @thread.pagination(current_user, page: (params[:page] || -1).to_i, user_is_contributor: true)
      @reportable = @report.reportable
      @user = @report.user
      @crumb = {
        stack: [
          { link: "/admin", title: "Admin" },
          { link: "/admin/reports", title: "Reports" },
          { title: @report.id },
        ],
        title: @thread.title
      }
    end
    
    def index
      if !user_signed_in?
        return head :unauthorized if params[:format] == 'json'
        return render_access_denied
      end
      
      if params[:reportable_class] && params[:reportable_id]
        @reportable = Reportable.find(params)
      end
      
      @records = Report.includes(:reportable)
      @records = @records.where(reportable: @reportable) if @reportable
      @records = Pagination.paginate(@records, params[:page].to_i, 50, true)

      @crumb = {
        stack: [
          { link: "/admin", title: "Admin" }
        ],
        title: "Reports"
      }
    end
    
    def update
      return render_access_denied if !current_user.is_contributor?
      return head :not_found if !(@report = Report.where(id: params[:report_id]).first)

      render json: {
        status: @report.change_status(current_user, params[:state].to_sym)
      }
    end
    
    def destroy
      return render_access_denied if !current_user.is_contributor?

      total = Report.open.count
      Report.open.change_status(:close)
      
      flash["success"] = "The status for #{total} reports have been updated to Closed."
      
      redirect_to action: :index, controller: :admin
    end
    
    def new
      return head :not_found if !(@reportable = Reportable.find(params))

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
      return head :not_found if !(reportable = Reportable.find(params))
      reportable.report(anonymous_user_id, params)
      
      head :ok
    end
  end
end

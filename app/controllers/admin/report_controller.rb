module Admin
  class ReportController < ApplicationController
    before_action :authenticate_user!
    
    def view
      if @report = Report.where(id: params[:id]).first
        if user_signed_in? && (current_user.is_contributor? || current_user.id == @report.user_id)
          @thread = @report.comment_thread
          @order = '0'
          @results = @comments = Pagination.paginate(@thread.get_comments(true), (params[:page] || -1).to_i, 10, false)
          @video = @report.video
          @user = @report.user
          return
        end
      end
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
    end
    
    def page
      @page = params[:page].to_i
      @results = Pagination.paginate(Report.includes(:video).where(resolved: nil), @page, 40, false)
      render json: {
        content: render_to_string(partial: 'report_thumb.html.erb', collection: @results.records),
        pages: @results.pages,
        page: @results.page
      }
    end
    
    def new
      @video = Video.where(id: params[:id]).first
      if @video
        return render json: {
          content: render_to_string(partial: 'new', locals: { video: @video, report: Report.new })
        }
      end
      head 401
    end
    
    def create
      if @video = Video.where(id: params[:id]).first
        @report = params[:report]
        @report = Report.create(video_id: @video.id,
                                first: @report[:first],
                                source: @report[:source],
                                content_type_unrelated: @report[:content_type_unrelated] == '1',
                                content_type_offensive: @report[:content_type_offensive] == '1',
                                content_type_disturbing: @report[:content_type_disturbing] == '1',
                                content_type_explicit: @report[:content_type_explicit] == '1',
                                copyright_holder: @report[:copyright_holder],
                                subject: @report[:subject],
                                other: @report[:other])
        @report.name = @report[:name] || (user_signed_in? ? current_user.username : "")
        @report.user_id = current_user.id if user_signed_in?
        @report.comment_thread = CommentThread.create(user_id: @report.user_id, title: "Report: " + @video.title)
        @report.save
        Notification.notify_admins(@report,
                                   "A new <b>Report</b> has been submitted for <b>" + @video.title + "</b>", @report.comment_thread.location)
        return head :ok
      end
      head 401
    end
  end
end

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
      @video = @report.video
      @user = @report.user
      
    end
    
    def index
      if !user_signed_in?
        return head 401
      end
      
      @records = Report.includes(:video).where(resolved: nil)
      render_pagination 'thumb', @records, params[:page].to_i, 40, false
    end
    
    def new
      if !(@video = Video.where(id: params[:video_id]).first)
        return head 401
      end
      
      render json: {
        content: render_to_string(partial: 'new', locals: {
          video: @video,
          report: Report.new
        })
      }
    end
    
    def create
      if !(@video = Video.where(id: params[:video_id]).first)
        head :not_found
      end
      
      @report = params[:report]
      @report = Report.create(
        video_id: @video.id,
        first: @report[:first],
        source: @report[:source] || @report[:target],
        content_type_unrelated: @report[:content_type_unrelated] == '1',
        content_type_offensive: @report[:content_type_offensive] == '1',
        content_type_disturbing: @report[:content_type_disturbing] == '1',
        content_type_explicit: @report[:content_type_explicit] == '1',
        copyright_holder: @report[:copyright_holder],
        subject: @report[:subject],
        other: @report[:note] || @report[:other],
        name: @report[:name] || (user_signed_in? ? current_user.username : "")
      )
      if user_signed_in?
        @report.user_id = current_user.id
      end
      @report.comment_thread = CommentThread.create(
        user_id: @report.user_id,
        title: "Report: " + @video.title
      )
      @report.save
      Notification.notify_admins(@report, "A new <b>Report</b> has been submitted for <b>" + @video.title + "</b>", @report.comment_thread.location)
      head :ok
    end
  end
end

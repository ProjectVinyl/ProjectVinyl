class HistoryController < ApplicationController
  def index
    if !(@video = Video.where(id: params[:id]).first)
      return render '/layouts/error', locals: { title: 'Nothing to see here!', description: "This is not the video you are looking for." }
    end
    if @video.duplicate_id > 0
      flash[:alert] = 'The video you are looking for has been marked as a duplicate of the one below.'
      return redirect_to action: 'view', id: @video.duplicate_id
    end
    @page = (params[:page] || 0).to_i
    @history = TagHistory.where(video_id: @video.id).order(:created_at)
    @history = Pagination.paginate(@history, @page, 20, true)
  end

  def page
    @video = Video.where(id: params[:id]).first
    @records = TagHistory.where(video_id: params[:id]).order(:created_at)
    if @records.count > 0
      return render_pagination 'history/change', Pagination.paginate(@records, params[:page].to_i, 20, true)
    end
    render json: {
      content: render_to_string(partial: '/history/wardenderpy'),
      pages: 0,
      page: 0
    }
  end
end

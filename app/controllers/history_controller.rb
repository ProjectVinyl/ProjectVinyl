class HistoryController < ApplicationController
  def index
    if !(@video = Video.where(id: params[:id]).first)
      return render_error(
        title: 'Nothing to see here!',
        description: "This is not the video you are looking for."
      )
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
    @records = Pagination.paginate(@records, params[:page].to_i, 20, true)
    if @records.count == 0
      return render_empty_pagination 'history/wardenderpy'
    end
    render_pagination_json 'history/change', @records
  end
end

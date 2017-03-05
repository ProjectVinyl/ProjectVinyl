class HistoryController < ApplicationController
  def view
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
    @page = params[:page].to_i
    @results = TagHistory.where(video_id: params[:id]).order(:created_at)
    @results = Pagination.paginate(@results, @page, 20, true)
    return render json: {
      content: @results.count > 0 ? render_to_string(partial: '/history/change.html.erb', collection: @results.records) : render_to_string(partial: '/history/wardenderpy'),
      pages: @results.pages,
      page: @results.page
    }
  end
end

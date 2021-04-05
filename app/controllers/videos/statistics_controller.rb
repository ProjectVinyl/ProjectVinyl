module Videos
  class StatisticsController < BaseVideosController
    def show
      head :not_found if !(@video = Video.where(id: params[:video_id]).first)
    end
  end
end

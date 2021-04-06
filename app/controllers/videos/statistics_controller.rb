module Videos
  class StatisticsController < BaseVideosController
    def show
      head :not_found if !(@video = Video.where(id: params[:video_id]).first)

      @crumb = {
        stack: [
          { title: 'Videos' },
          { link: @video.link, title: "##{@video.id}" }
        ],
        title: 'Statistics'
      }
    end
  end
end

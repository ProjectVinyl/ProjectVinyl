module Videos
  class DetailsController < BaseVideosController
    def update
      check_then do |video|
        if (changes = video.set_tag_string(params[:tags]))
          TagHistory.record_tag_changes(changes[0], changes[1], video.id, current_user.id)
        end

        if video.source != params[:source]
          video.source = params[:source]
          TagHistory.record_source_changes(video, current_user.id)
        end

        video.save

        render json: {
          source: video.source,
          results: video.tags.order(:name).jsons(current_user)
        }
      end
    end
  end
end

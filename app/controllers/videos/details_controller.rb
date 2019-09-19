module Videos
  class DetailsController < BaseVideosController
    def update
      check_then do |video|
        if changes = Tag.load_tags(params[:tags], video)
          TagHistory.record_tag_changes(changes[0], changes[1], video.id, current_user.id)
        end

        if video.source != params[:source]
          video.set_source(params[:source])
          TagHistory.record_source_changes(video, current_user.id)
        end

        video.save

        head :ok
      end
    end
  end
end

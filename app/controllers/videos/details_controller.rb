module Videos
  class DetailsController < BaseVideosController
    def update
      check_then do |video|

        begin
          if (changes = video.set_all_tags(TagRule.test(Tag.ids_from_string(params[:tags]))))
            TagHistory.record_tag_changes(changes[0], changes[1], video.id, current_user.id)
          end
        rescue TagRule::RuleNotFulfilledError => e
          return render json: {
            error: {
              title: 'Tagging Requirements Not Met',
              msg: e.message
            }
          }
        end

        if video.source != params[:source]
          video.source = params[:source]
          TagHistory.record_source_changes(video, current_user.id)
        end

        video.save

        render json: {
          sources: video.external_sources.jsons,
          results: video.tags.order(:name).jsons(current_user)
        }
      end
    end
  end
end

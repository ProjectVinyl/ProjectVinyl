require 'projectvinyl/web/youtube'
require 'projectvinyl/web/youtube_oembed'

module Videos
  class ImportsController < Videos::BaseVideosController
    def new
      render partial: 'new'
    end
    
    def create
      yt_id = ProjectVinyl::Web::Youtube.video_id(params[:url])

      return render json: {
        error: "Invalid Url"
      } if yt_id.nil?

      begin
        problem = ProjectVinyl::Web::Youtube.validate_id(yt_id)
        return render json: {
          error: problem
        } if !problem.nil?
      end

      oembed = ProjectVinyl::Web::YoutubeOembed.get(yt_id)

      if params[:_intent] == 'check'
        return render json: {
          info: "Video ID: #{yt_id}, #{oembed[:title]} by #{oembed[:author_name]}, Provider: #{oembed[:provider_name]}"
        }
      end

      if (@source = ExternalSource.youtube.where(key: yt_id).first)
        return render json: {
          error: "Video already exists at: #{url_for(@source.video)}"
        } if @source.video
      end

      if params[:order].to_i == 0
        Import::VideoJob.perform_later(current_user.id, yt_id)
        return render json: {
          info: 'Thank you! Your video will appear shortly.'
        }
      end

      response = Import::VideoJob.queue_and_publish_now(current_user, yt_id, publish: false)

      return render json: {
        error: response[:response]
      } if !response[:ok]

      @video = response[:record]
      @upload_gateway = upload_gateway
      @user = current_user

      return render json: {
        tab: render_to_string(partial: 'videos/form/uploader_frame_tab', formats: :html, locals: {
          video: @video,
          tab_id: '{id}'
        }),
        editor: render_to_string(partial: 'videos/form/uploader_frame_content', formats: :html, locals: {
          video: @video,
          tab_id: '{id}'
        })
      }
    end
  end
end

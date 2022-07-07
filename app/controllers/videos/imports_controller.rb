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

      if (@source = ExternalSource.youtube.where(key: yt_id).first)
        return render json: {
          error: "Item already exists"
        } if @source.video
      end

      response = Import::VideoJob.queue_and_return(current_user, yt_id)
      
      return render json: {
        error: response[:response]
      } if !response[:ok]

      return render json: {
        tab: render_to_string(partial: 'videos/form/uploader_frame_tab', formats: :html, locals: {
          video: response[:record],
          tab_id: '{id}'
        }),
        editor: render_to_string(partial: 'videos/form/uploader_frame_content', formats: :html, locals: {
          video: response[:record],
          tab_id: '{id}'
        })
      }
    end
  end
end

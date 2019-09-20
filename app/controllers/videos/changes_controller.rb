module Videos
  class ChangesController < ApplicationController
    def index
      if !(@video = Video.where(id: params[:video_id]).first)
        return render_error(
          title: 'Nothing to see here!',
          description: 'This is not the video you are looking for.'
        )
      end

      if params[:format] != 'json' && @video.duplicate_id > 0
        flash[:alert] = 'The video you are looking for has been marked as a duplicate of the one below.'
        return redirect_to action: 'view', id: @video.duplicate_id
      end

      @history = @video.tag_histories.includes(:tag, :user).order(:created_at)

      if params[:added]
        @history = @history.where(added: params[:added].to_i == 1)
      end

      @history = Pagination.paginate(@history, params[:page].to_i, 20, true)

      if params[:format] == 'json'
        if @history.count == 0
          return render_empty_pagination 'warden_derpy'
        end
        render_pagination_json 'change', @history
      end

      @crumb = {
        stack: [
          { title: 'Videos' },
          { link: @video.link, title: "##{@video.id}" }
        ],
        title: 'Tag Changes'
      }
    end
  end
end

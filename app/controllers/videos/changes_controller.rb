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
      @history = @history.where(added: params[:added].to_i == 1) if params[:added]
      @history = Pagination.paginate(@history, params[:page].to_i, 20, true)

      if params[:format] == 'json'
        return render_empty_pagination 'warden_derpy' if @history.count == 0
        render_paginated @history, partial: 'history/change', as: :json, headers: 'history/column_headers'
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

module External
  class WatchesController < ApplicationController
    def show
      if (@source = ExternalSource.youtube.where(key: params[:v]).first)
        return redirect_to @video.link if (@video = @source.video)
      end

      if user_signed_in?
        if ApplicationHelper.read_only && !current_user.is_contributor?
          flash[:info] = "Project Vinyl is in read only mode. Sorry for the inconvenience!"
          flash[:error] = "The requested video could be found: #{params[:v]}"
        else
          response = Import::VideoJob.queue_and_publish_now(current_user, params[:v])

          flash[:info] = response[:response]
          return redirect_to action: :show, controller: '/videos', id: response[:id] if response[:ok]
        end
      else
        flash[:error] = "The requested video could be found: #{params[:v]}"
      end

      redirect_to '/'
    end
  end
end

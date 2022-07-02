module External
  class WatchesController < ApplicationController
    def show
      if (@source = ExternalSource.where(key: params[:v], provider: 'youtube').first)
        return redirect_to @video.link if (@video = @source.video)
      end

      if user_signed_in?
        response = ImportYtVideoJob.queue_video(current_user, params[:v])

        flash[:info] = response[:response]
        return redirect_to action: :show, controller: '/videos', id: response[:id] if response[:ok]
      else
        flash[:error] = "The requested video could be found: #{params[:v]}"
      end

      redirect_to '/'
    end
  end
end
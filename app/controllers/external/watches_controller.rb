module External
  class WatchesController < ApplicationController
    def show
      if (@source = ExternalSource.where(key: params[:v], provider: 'youtube').first)
        if (@video = @source.video)
          redirect_to @video.link
        end
      end
    end
  end
end
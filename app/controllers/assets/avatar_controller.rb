module Assets
  class AvatarController < ApplicationController
    include Assetable

    def show
      if params[:file_name] == 'banner'
        redirect_to '/images/new-banner.jpg'
      else
        redirect_to '/images/default-avatar.png'
      end
    end
  end
end
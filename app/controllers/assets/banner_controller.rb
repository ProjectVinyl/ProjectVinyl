module Assets
  class BannerController < ApplicationController
    include Assetable

    def show
      serve_img('new-banner.jpg')
    end
  end
end

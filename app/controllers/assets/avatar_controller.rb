module Assets
  class ImagesController < ApplicationController
    include Assetable

    def show
      serve_img('default-avatar.png')
    end
  end
end
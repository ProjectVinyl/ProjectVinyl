module Assets
  class CoverController < ApplicationController
    include Assetable

    def show
      if !params[:small]
        return serve_img('default-cover.png')
      end

      png = Rails.root.join('public', 'cover', params[:id])

      if !File.exist?("#{png}.png")
        return serve_img('default-cover-small.png')
      end

      Ffmpeg.extract_tiny_thumb_from_existing("#{png}.png", "#{png}-small.png")
      serve_direct("#{png}.png", 'image/png')
    end
  end
end
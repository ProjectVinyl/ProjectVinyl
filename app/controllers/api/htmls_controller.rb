module Api
  class HtmlsController < ApplicationController
    def show
      render json: ProjectVinyl::Bbc::Bbcode.from_bbc(params[:content]).to_json
    end
  end
end

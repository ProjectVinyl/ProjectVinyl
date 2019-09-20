module Api
  class BbcodesController < ApplicationController
    def show
      render json: ProjectVinyl::Bbc::Bbcode.from_html(params[:content]).to_json
    end
  end
end

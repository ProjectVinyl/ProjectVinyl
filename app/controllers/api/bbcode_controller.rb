require 'projectvinyl/bbc/bbcode'

module Api
  class BbcodeController < ApplicationController
    def html_to_bbcode
      render_json(ProjectVinyl::Bbc::Bbcode.from_html(params[:content]))
    end
    
    def bbcode_to_html
      render_json(ProjectVinyl::Bbc::Bbcode.from_bbc(params[:content]))
    end
    
    private
    def render_json(nodes)
      render json: {
        html: nodes.outer_html,
        bbc: nodes.outer_bbc
      }
    end
  end
end

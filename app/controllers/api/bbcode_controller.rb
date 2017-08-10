require 'projectvinyl/bbc/bbcode'

module Api
  class BbcodeController < ApplicationController
    def html_to_bbcode
      @nodes = ProjectVinyl::Bbc::Bbcode.from_html(params[:content])
      render json: {
        html: @nodes.outer_html,
        bbc: @nodes.outer_bbc
      }
    end
    
    def bbcode_to_html
      @nodes = ProjectVinyl::Bbc::Bbcode.from_bbc(params[:content])
      render json: {
        html: @nodes.outer_html,
        bbc: @nodes.outer_bbc
      }
    end
  end
end

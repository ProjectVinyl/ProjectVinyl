module Assets
  class BaseAssetsController < ApplicationController
    include Assetable

    protected
    def with_video
      yield(Video.where(id: params[:id]).first)
    end

    def special_access?
      user_signed_in? && current_user.is_contributor?
    end
  end
end

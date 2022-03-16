module Assets
  class BaseAssetsController < ActionController::Base
    include Errorable
    include Assetable

    skip_before_action :set_ahoy_cookies
    skip_before_action :track_ahoy_visit
    skip_around_action :set_ahoy_request_store

    protected
    def with_video
      yield(Video.where(id: params[:id]).first)
    end

    def special_access?
      user_signed_in? && current_user.is_contributor?
    end
  end
end

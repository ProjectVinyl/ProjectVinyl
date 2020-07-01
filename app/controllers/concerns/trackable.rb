module Trackable
  extend ActiveSupport::Concern

  included do
    before_action :set_start_time
    after_action :poke_user, if: :user_signed_in?
  end

  protected
  def set_start_time
    @start_time = Time.now
  end

  def poke_user
    current_user.poke
  end

  def after_sign_in_path_for(resource)
    return root_url if request.referrer == request.url
    request.referrer
  end

  def after_sign_out_path_for(resource_or_scope)
    return root_url if request.referrer == request.url
    request.referrer
  end
end

class ServicesController < ApplicationController
  before_action :authenticate_user!
  
  def register
    NotificationReceiver.create({
      user: current_user,
      endpoint: params[:endpoint],
      pauth: params[:p256dh],
      auth: params[:auth]
    })
    
    head :ok
  end
  
  def deregister
    NotificationReceiver.where(
      user: current_user,
      auth: params[:auth],
      pauth: params[:p256dh]
    ).destroy_all
    
    head :ok
  end
end

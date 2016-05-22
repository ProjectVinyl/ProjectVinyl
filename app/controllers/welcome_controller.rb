class WelcomeController < ApplicationController
  def index
    @today = Video.where(created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).limit(16)
    @yesterday = Video.where(created_at: Time.zone.now.yesterday.beginning_of_day..Time.zone.yesterday.end_of_day).limit(16)
  end
end

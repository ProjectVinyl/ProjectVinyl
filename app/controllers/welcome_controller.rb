class WelcomeController < ApplicationController
  def index
    @month = Video.where(hidden: false, created_at: Time.zone.now.beginning_of_month..1.week.ago).order(:created_at).reverse_order().limit(16)
    @week = Video.where(hidden: false, created_at: 1.week.ago..Time.zone.now.yesterday.beginning_of_day).order(:created_at).reverse_order().limit(16)
    @yesterday = Video.where(hidden: false, created_at: Time.zone.now.yesterday.beginning_of_day..Time.zone.yesterday.end_of_day).order(:created_at).reverse_order().limit(32)
    @today = Video.where(hidden: false, created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).order(:created_at).reverse_order().limit(32)
  end
end

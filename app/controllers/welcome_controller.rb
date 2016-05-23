class WelcomeController < ApplicationController
  def index
    @month = Video.where(created_at: Time.zone.now.beginning_of_month..Time.zone.now.beginning_of_week).order(:created_at).reverse_order().limit(64)
    @week = Video.where(created_at: Time.zone.now.beginning_of_week..Time.zone.now.yesterday.beginning_of_day).order(:created_at).reverse_order().limit(32)
    @yesterday = Video.where(created_at: Time.zone.now.yesterday.beginning_of_day..Time.zone.yesterday.end_of_day).order(:created_at).reverse_order().limit(16)
    @today = Video.where(created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).order(:created_at).reverse_order().limit(16)
  end
end

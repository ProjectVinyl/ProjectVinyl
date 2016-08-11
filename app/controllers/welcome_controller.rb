class WelcomeController < ApplicationController
  def index
    @popular = Video.where(hidden: false, created_at: (Date.today - 90)..Time.zone.now.end_of_day).where('views > ? OR score > ?', 0, 0).order(:score, :views).reverse_order.limit(4)
    @month = Video.where(hidden: false, created_at: Time.zone.now.beginning_of_month..1.week.ago).order(:created_at).reverse_order.limit(8)
    @week = Video.where(hidden: false, created_at: 1.week.ago..Time.zone.now.yesterday.beginning_of_day).order(:created_at).reverse_order.limit(16)
    @yesterday = Video.where(hidden: false, created_at: Time.zone.yesterday.beginning_of_day..Time.zone.yesterday.end_of_day).order(:created_at).reverse_order.limit(32)
    @today = Video.where(hidden: false, created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).order(:created_at).reverse_order.limit(32)
  end
end

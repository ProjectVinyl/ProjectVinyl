class StaffController < ApplicationController
  def donate
    render partial: 'donate' if params[:format] == 'json'
  end
end

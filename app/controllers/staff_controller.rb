class StaffController < ApplicationController
  def donate
    render partial: 'donate', formats: [:html] if params[:format] == 'json'
  end
end

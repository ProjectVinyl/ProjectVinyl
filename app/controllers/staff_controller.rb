class StaffController < ApplicationController
  def donate
    @crumb = {
      stack: [ ],
      title: 'Support Us'
    }
    
    render partial: 'donate', formats: [:html] if params[:format] == 'json'
  end
end

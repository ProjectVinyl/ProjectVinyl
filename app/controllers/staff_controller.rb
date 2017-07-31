class StaffController < ApplicationController
  def index
  end

  def copyright
  end

  def policy
  end

  def donate
  end
  
  def ajax_donate
    render partial: "staff/donate"
  end
end

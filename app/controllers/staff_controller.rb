class StaffController < ApplicationController
  def index
  end
  
  def copyright
  end
  
  def policy
  end
  
  def donate
    render partial: "donate"
  end
end

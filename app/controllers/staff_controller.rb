class StaffController < ApplicationController
  def ajax_donate
    render partial: "staff/donate"
  end
end

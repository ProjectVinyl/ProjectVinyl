module Ajax
  class StaffController < ApplicationController
    def donate
      render partial: "staff/donate"
    end
  end
end


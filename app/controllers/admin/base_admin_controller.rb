module Admin
  class BaseAdminController < ApplicationController
    before_action :authenticate_user!
  end
end

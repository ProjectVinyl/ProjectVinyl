class SettingsController < ApplicationController
  def edit
    @current_tab = (params[:tab] || "local").to_sym
    @tab_selection_hash = Hash.new({})
    @tab_selection_hash[@current_tab] = {class: "selected"}

    if user_signed_in?
      redirect_to edit_user_registration_path(tab: @current_tab)
    end
  end
end

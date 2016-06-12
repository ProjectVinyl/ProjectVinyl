class HiddenVideos < ActiveRecord::Migration
  def change
    add_column :videos, :hidden, :boolean, default: false
    Video.reset_column_information
    Video.update_all(hidden: false)
  end
end

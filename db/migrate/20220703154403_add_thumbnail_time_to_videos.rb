class AddThumbnailTimeToVideos < ActiveRecord::Migration[5.1]
  def change
    add_column :videos, :thumbnail_time, :float, default: 0
    Video.reset_column_information
    Video.update_all(thumbnail_time: 0)
  end
end

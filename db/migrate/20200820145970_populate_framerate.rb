class PopulateFramerate < ActiveRecord::Migration[5.1]
  def change
    unless column_exists? :videos, :framerate
      add_column :videos, :framerate, :integer
    end
    UpdateMetadataJob.perform_later
  end
end

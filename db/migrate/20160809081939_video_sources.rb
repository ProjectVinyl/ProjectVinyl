class VideoSources < ActiveRecord::Migration
  def change
    add_column :videos, :source, :string, default: ""
  end
end

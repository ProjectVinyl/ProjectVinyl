class ImprovedWorkers < ActiveRecord::Migration
  def change
    add_column :processing_workers, :video_id, :integer
  end
end

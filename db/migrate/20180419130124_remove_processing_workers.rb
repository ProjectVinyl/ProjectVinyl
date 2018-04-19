class RemoveProcessingWorkers < ActiveRecord::Migration[5.1]
  def change
  	drop_table :processing_workers
  end
end

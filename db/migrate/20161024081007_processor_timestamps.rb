class ProcessorTimestamps < ActiveRecord::Migration
  def change
    change_table(:processing_workers) {|t| t.timestamps }
    ProcessingWorker.reset_column_information
    ProcessingWorker.update_all(created_at: DateTime.now, updated_at: DateTime.now)
  end
end

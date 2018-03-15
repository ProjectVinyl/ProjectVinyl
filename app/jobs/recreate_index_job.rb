class RecreateIndexJob < ApplicationJob
  queue_as :default

  def perform(user_id, table)
    table = table.constantize
    table.__elasticsearch__.delete_index!
    table.__elasticsearch__.create_index!
    table.import
    
    Report.generate_report!(
      "Indexing table #{table} (#{Time.zone.now})",
      "Action 'Recreate #{table} Index' has been completed",
      { user_id: user_id, first: "System", other: "Complete" }
    )
  end
end

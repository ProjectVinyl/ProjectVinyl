class RefreshIndexJob < ApplicationJob
  queue_as :default

  def perform(user_id, table)
    table = table.constantize

    if !table.__elasticsearch__.index_exists?
      table.__elasticsearch__.create_index!
      table.import
    else
      table.find_each(batch_size: 500){|model| model.update_index(defer: false)}
    end

    Report.generate_report!(
      "Indexing table #{table} (#{Time.zone.now})",
      "Action 'Refresh #{table} Index' has been completed",
      { user_id: user_id, first: "System", other: "Complete" }
    )
  end
end

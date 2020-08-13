class UpdateIndexJob < ApplicationJob
  queue_as :default

  def perform(table, ids)
    table = table.constantize
    table.where(id: ids).find_each(batch_size: 500){|model| model.update_index(defer: false)}
  end
end

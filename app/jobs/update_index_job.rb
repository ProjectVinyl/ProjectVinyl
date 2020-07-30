class UpdateIndexJob < ApplicationJob
  queue_as :default

  def perform(table, id)
    table = table.constantize

    if (model = table.where(id: id).first)
      model.update_index(false)
    end
  end
end

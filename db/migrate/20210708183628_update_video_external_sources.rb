class UpdateVideoExternalSources < ActiveRecord::Migration[5.1]
  def change
    ProcessExternalSourcesJob.perform_later
  end
end

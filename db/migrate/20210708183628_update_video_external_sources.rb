class UpdateVideoExternalSources < ActiveRecord::Migration[5.1]
  def change
    Sources::ImportJob.perform_later
  end
end

class AddUniqueConstraintToVideoSources < ActiveRecord::Migration[5.1]
  def change
    add_column :external_sources, :url, :string, default: nil
    ExternalSource.delete_all
    Sources::ImportJob.perform_later
    add_index :external_sources, [:video_id, :url], :unique => true
  end
end

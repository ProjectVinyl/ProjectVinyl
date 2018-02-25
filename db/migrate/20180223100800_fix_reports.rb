class FixReports < ActiveRecord::Migration[5.1]
  def change
    rename_column :reports, :video_id, :reportable_id
    add_column :reports, :reportable_type, :string
    Report.where('reportable_id IS NOT NULL').update_all('reportable_type = "Video"')
  end
end

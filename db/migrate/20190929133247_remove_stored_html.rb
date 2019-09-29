class RemoveStoredHtml < ActiveRecord::Migration[5.1]
  def change
    remove_column :comments, :html_content
    remove_column :site_notices, :html_message
  end
end

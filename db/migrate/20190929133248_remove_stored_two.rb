class RemoveStoredHtml < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :html_description
    remove_column :users, :html_bio

    remove_column :videos, :html_description
    remove_column :albums, :html_description
  end
end

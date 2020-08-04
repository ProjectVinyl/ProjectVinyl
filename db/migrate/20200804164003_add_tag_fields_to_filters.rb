class AddTagFieldsToFilters < ActiveRecord::Migration[5.1]
  def change
    add_column :site_filters, :spoiler_tags, :text
    add_column :site_filters, :hide_tags, :text
  end
end

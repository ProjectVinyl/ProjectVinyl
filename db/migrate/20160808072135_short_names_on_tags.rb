class ShortNamesOnTags < ActiveRecord::Migration
  def change
    add_column :tags, :short_name, :string, default: ""
    change_column :tags, :name, :string, default: ""
  end
end

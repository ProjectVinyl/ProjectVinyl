class AddShowFlagToTagTypes < ActiveRecord::Migration
  def change
    add_column :tag_types, :hidden, :boolean, default: false
  end
end

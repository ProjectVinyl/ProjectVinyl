class TagAliases < ActiveRecord::Migration
  def change
    add_column :tags, :alias_id, :integer
  end
end

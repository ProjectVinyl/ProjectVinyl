class AddIndexOnImps < ActiveRecord::Migration[5.1]
  def change
    add_index :tag_implications, [:tag_id, :implied_id], unique: true
  end
end

class AddIndex < ActiveRecord::Migration
  def change
    add_index :videos, :created_at
  end
end

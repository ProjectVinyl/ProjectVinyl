class Hotness < ActiveRecord::Migration
  def change
    add_column :videos, :heat, :integer
  end
end

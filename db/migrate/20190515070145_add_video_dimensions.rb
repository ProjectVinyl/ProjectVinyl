class AddVideoDimensions < ActiveRecord::Migration[5.1]
  def change
    add_column :videos, :width, :integer
    add_column :videos, :height, :integer
  end
end

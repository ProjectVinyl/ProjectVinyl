class ThreeStateProcessing < ActiveRecord::Migration
  def change
    change_column :videos, :processed, :boolean, default: nil
  end
end

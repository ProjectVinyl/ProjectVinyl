class Hotness < ActiveRecord::Migration
  def change
    add_column :videos, :heat, :integer
    Video.reset_column_information
    Video.all.each do |v|
      v.heat = v.computeHotness
      v.save
    end
  end
end

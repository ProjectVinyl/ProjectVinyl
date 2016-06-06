class Fix < ActiveRecord::Migration
  def change
    change_column :stars, :index, :integer, default: 0
  end
end

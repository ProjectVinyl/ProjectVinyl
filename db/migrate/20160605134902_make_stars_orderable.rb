class MakeStarsOrderable < ActiveRecord::Migration
  def change
    add_column :stars, :index, :boolean, default: 0
  end
end

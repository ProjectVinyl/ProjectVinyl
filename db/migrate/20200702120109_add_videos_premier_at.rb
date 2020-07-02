class AddVideosPremierAt < ActiveRecord::Migration[5.1]
  def change
    add_column :videos, :premiered_at, :datetime
  end
end

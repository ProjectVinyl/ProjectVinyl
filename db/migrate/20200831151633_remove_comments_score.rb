class RemoveCommentsScore < ActiveRecord::Migration[5.1]
  def change
    remove_column :comments, :score
  end
end

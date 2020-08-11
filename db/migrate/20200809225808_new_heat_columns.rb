class NewHeatColumns < ActiveRecord::Migration[5.1]
  def change
    add_column :comments, :likes_count, :integer

    change_column :videos, :heat, :float

    add_column :videos, :wilson_lower_bound, :float
    add_column :videos, :wilson_upper_bound, :float
    add_column :videos, :boosted_at, :datetime

    Comment.reset_column_information
    Comment.all.update_all('likes_count = (SELECT COUNT(*) FROM comment_votes WHERE comment_votes.comment_id = comments.id)')
  end
end

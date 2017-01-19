class CreateCommentVotes < ActiveRecord::Migration
  def change
    create_table :comment_votes do |t|
      t.integer :user_id
      t.integer :comment_id
      t.timestamps null: false
    end
    add_column :comments, :score, :integer
  end
end

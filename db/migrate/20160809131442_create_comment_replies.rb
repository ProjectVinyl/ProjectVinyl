class CreateCommentReplies < ActiveRecord::Migration
  def change
    create_table :comment_replies do |t|
      t.integer :parent_id
      t.integer :comment_id
    end
  end
end

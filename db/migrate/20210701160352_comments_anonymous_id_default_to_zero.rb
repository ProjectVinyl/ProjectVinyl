class CommentsAnonymousIdDefaultToZero < ActiveRecord::Migration[5.1]
  def change
    change_column :comments, :anonymous_id, :integer, default: 0
    Comment.reset_column_information
    Comment.update_all('anonymous_id = 0 WHERE anonymous_id IS NULL')
  end
end

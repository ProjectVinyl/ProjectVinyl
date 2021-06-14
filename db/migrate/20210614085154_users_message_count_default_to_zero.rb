class UsersMessageCountDefaultToZero < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :message_count, :integer, default: 0
  end
end

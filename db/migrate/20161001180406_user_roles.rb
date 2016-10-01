class UserRoles < ActiveRecord::Migration
  def change
    add_column :users, :role, :integer, default: 0
    User.reset_column_information
    User.where(is_admin: true).update_all(role: 2)
    remove_column :users, :is_admin
  end
end

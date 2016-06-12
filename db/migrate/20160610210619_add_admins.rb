class AddAdmins < ActiveRecord::Migration
  def up
    add_column :users, :is_admin, :boolean, default: 0
    User.reset_column_information
    User.update_all(is_admin: 0)
  end
  
  def down
    remove_column :users, :is_admin
  end
end

class AddUserAssignedToTagTypes < ActiveRecord::Migration[5.1]
  def change
    add_column :tag_types, :user_assignable, :boolean, default: true
    
    TagType.reset_column_information
    TagType.where(prefix: [:rating, :warning]).update_all(user_assignable: false)
  end
end

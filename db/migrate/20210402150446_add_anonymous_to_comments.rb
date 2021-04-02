class AddAnonymousToComments < ActiveRecord::Migration[5.1]
  def change
    add_column :comments, :anonymous_id, :integer
  end
end

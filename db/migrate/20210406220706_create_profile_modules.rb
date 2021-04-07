class CreateProfileModules < ActiveRecord::Migration[5.1]
  def change
    create_table :profile_modules do |t|
      t.integer :user_id
      t.integer :column
      t.integer :index
      t.string :module_type
      t.timestamps null: false
    end
    add_index :profile_modules, [:user_id, :column]

    User.all.each do |user|
      ProfileModule.seed(user)
    end
  end
end

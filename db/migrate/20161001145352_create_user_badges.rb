class CreateUserBadges < ActiveRecord::Migration
  def change
    create_table :user_badges do |t|
      t.integer :badge_id
      t.integer :user_id
      t.string :custom_title
      t.timestamps null: false
    end
  end
end

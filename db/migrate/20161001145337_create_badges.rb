class CreateBadges < ActiveRecord::Migration
  def change
    create_table :badges do |t|
      t.string :title
      t.string :colour
      t.string :icon
      t.integer :badge_type, default: 0
      t.timestamps null: false
    end
    Badge.create(title: "Duck", colour: "yellow", icon: "duck", badge_type: 1)
  end
end

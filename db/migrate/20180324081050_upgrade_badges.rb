class UpgradeBadges < ActiveRecord::Migration[5.1]
  def change
    add_column :badges, :note, :string
    add_column :badges, :description, :string
    add_column :badges, :hidden, :boolean, default: false
  end
end

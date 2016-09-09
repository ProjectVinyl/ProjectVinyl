class FiltersEtc < ActiveRecord::Migration
  def change
    add_column :tag_subscriptions, :watch, :boolean, default: false
    add_column :tag_subscriptions, :spoiler, :boolean, default: false
    add_column :tag_subscriptions, :hide, :boolean, default: false
  end
end

class RemoveOldFilters < ActiveRecord::Migration[5.1]
  def change
    TagSubscription.where(watch: false).destroy_all
    remove_column :tag_subscriptions, :hide
    remove_column :tag_subscriptions, :spoiler
    remove_column :tag_subscriptions, :watch
  end
end

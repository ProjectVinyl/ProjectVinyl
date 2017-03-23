class CacheBusting < ActiveRecord::Migration
  def change
    add_column :users, :cached_at, :datetime
    User.update_all('cached_at = updated_at')
    add_column :videos, :cached_at, :datetime
    Video.update_all('cached_at = updated_at')
  end
end

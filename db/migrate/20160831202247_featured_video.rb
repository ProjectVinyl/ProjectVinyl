class FeaturedVideo < ActiveRecord::Migration
  def change
    add_column :videos, :featured, :boolean, default: false
  end
end

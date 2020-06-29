class AddArchiveFlag < ActiveRecord::Migration[5.1]
  def change
    add_column :videos, :listing, :integer, default: 0
    add_column :users, :default_listing, :integer, default: 0

    connection = ActiveRecord::Base.connection
    connection.execute('UPDATE videos SET listing = 0');
    connection.execute('UPDATE users SET default_listing = 0');
  end
end

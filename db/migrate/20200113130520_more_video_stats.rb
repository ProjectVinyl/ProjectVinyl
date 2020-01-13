class MoreVideoStats < ActiveRecord::Migration[5.1]
  def change
    add_column :videos, :play_count, :integer, default: 0
    
    connection = ActiveRecord::Base.connection
    connection.execute('UPDATE videos SET play_count = views');
  end
end

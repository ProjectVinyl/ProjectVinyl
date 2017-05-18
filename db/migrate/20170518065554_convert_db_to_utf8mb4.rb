class ConvertDbToUtf8mb4 < ActiveRecord::Migration
  def change
    puts "[!!!IMPORTANT!!!]"
    puts "Remember to update /config/database.yml with: 'encoding: utf8mb4'"
    
    @chars = "utf8mb4 COLLATE utf8mb4_unicode_ci"
    @charset = "CHARACTER SET #{@chars}"
    execute "ALTER DATABASE `#{connection.current_database}` #{@charset}"
    
    connection.tables.each do |table|
      execute "ALTER TABLE #{table} CONVERT TO #{@charset}"
    end
    
    #restore default values
    
    #album_items
    #albums
    execute "ALTER TABLE albums CHANGE featured featured INT(11) DEFAULT 0"
    execute "ALTER TABLE albums CHANGE hidden hidden TINYINT(1) DEFAULT 0"
    #artist_genres
    #badges
    #boards
    #comment_replies
    #comment_threads
    #comment_votes
    #comments
    #notifications
    execute "ALTER TABLE notifications CHANGE unread unread tinyint(1) DEFAULT 1"
    #pms
    #processing_workers    
    execute "ALTER TABLE processing_workers CHANGE running running tinyint(1) DEFAULT 1"
    #reports
    #tag_histories
    #tag_implications
    #tag_subscriptions
    #tag_type_implications
    #tag_types
    #tags
    execute "ALTER TABLE tags CHANGE video_count video_count int(11) DEFAULT 1"
    execute "ALTER TABLE tags CHANGE user_count user_count int(11) DEFAULT 1"
    #thread_subscriptions
    #user_badges
    #users
    execute "ALTER TABLE users CHANGE updated_at updated_at datetime NOT NULL"
    #video_genres
    #videos
    execute "ALTER TABLE videos CHANGE score score int(11) DEFAULT 0"
    execute "ALTER TABLE videos CHANGE hidden hidden tinyint(1) DEFAULT 0"
    execute "ALTER TABLE videos CHANGE views views int(11) DEFAULT 0"
    #votes
    
    puts "[!!!IMPORTANT!!!]"
    puts "Remember to update /config/database.yml with: 'encoding: utf8mb4'"
  end
end

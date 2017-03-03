class AddElasticSearch < ActiveRecord::Migration
  def change
    Video.__elasticsearch__.create_index!
    Video.import
    User.__elasticsearch__.delete_index!
    User.__elasticsearch__.create_index!
    User.import
  end
end

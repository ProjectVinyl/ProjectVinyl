class AddTimestampsToNotices < ActiveRecord::Migration[5.1]
  def change
    change_table :site_notices do |t|
      t.timestamps null: false, default: :now
    end
  end
end

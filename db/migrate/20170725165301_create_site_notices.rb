class CreateSiteNotices < ActiveRecord::Migration[5.1]
  def change
    create_table :site_notices do |t|
      t.boolean :active, default: true
      t.string :message
      t.string :html_message
    end
  end
end

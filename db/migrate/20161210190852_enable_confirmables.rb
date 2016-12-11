class EnableConfirmables < ActiveRecord::Migration
  def change
    change_table(:users) do |t|
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email
    end
    add_index :users, :confirmation_token, :unique => true
    User.update_all('unconfirmed_email = email')
  end
end

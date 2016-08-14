class AddProcessingManagerStatus < ActiveRecord::Migration
  def change
    create_table :processing_workers do |t|
      t.boolean :running, default: false
      t.string :status, default: ""
      t.text :message
    end
  end
end

class CreateTagRules < ActiveRecord::Migration[5.1]
  def change
    create_table :tag_rules do |t|
      t.string :message
      t.integer :when_present, array: true, default: []
      t.integer :all_of, array: true, default: []
      t.integer :none_of, array: true, default: []
      t.integer :any_of, array: true, default: []
      t.timestamps
    end
  end
end

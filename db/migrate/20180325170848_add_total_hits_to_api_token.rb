class AddTotalHitsToApiToken < ActiveRecord::Migration[5.1]
  def change
    add_column :api_tokens, :total_hits, :integer, default: 0
  end
end

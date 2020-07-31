class CreateSiteFilters < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :site_filter_id, :integer, default: 0
    create_table :site_filters do |t|
      t.text :name
      t.text :description
      t.integer :user_id
      t.text :hide_filter
      t.text :spoiler_filter
      t.boolean :preferred
      t.timestamps null: false
    end

    #Default filters
    SiteFilter.create({
      id: 1,
      preferred: true,
      name: 'Everything',
      description: 'The Default Everything',
      hide_filter: '',
      spoiler_filter: ''
    })
  end
end

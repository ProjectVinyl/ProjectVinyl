class OrganiseTags < ActiveRecord::Migration[5.1]
  def change
    add_index :tag_types, [:prefix], unique: true

    add_column :tags, :namespace, :string, default: ''
    add_column :tags, :suffex, :string, default: ''
    add_column :tags, :slug, :string, default: ''
    
    Tag.reset_column_information
    Tag.where("name LIKE '%:%'")
       .update_all("slug = replace(name, ':', '-colon-'), namespace = split_part(name, ':', 1), suffex = replace(name, concat(split_part(name, ':', 1), ':'), '')")
  end
end

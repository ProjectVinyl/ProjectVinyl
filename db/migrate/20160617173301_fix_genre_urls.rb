class FixGenreUrls < ActiveRecord::Migration
  def change
    add_column :genres, :safe_name, :string
    Genre.reset_column_information
    Genre.all.each do |g|
      g.safe_name = g.name.gsub(/(\/|[^a-zA-Z0-9\-])+/,'+')
      g.save
    end
  end
end

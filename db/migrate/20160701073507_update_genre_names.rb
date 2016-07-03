class UpdateGenreNames < ActiveRecord::Migration
  def change
    Genre.all.each do |g|
      g.safe_name = ApplicationHelper.url_safe(g.name)
      g.save
    end
  end
end

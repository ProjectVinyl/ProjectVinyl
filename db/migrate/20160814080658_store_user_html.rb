class StoreUserHtml < ActiveRecord::Migration
  def change
    add_column :users, :html_description, :text
    add_column :users, :html_bio, :text
    add_column :videos, :html_description, :text
    add_column :albums, :html_description, :text
    Video.all.group(:description).pluck(:description).each do |d|
      Video.where(description: d).update_all(html_description: BbcodeHelper.emotify(d))
    end
    User.all.group(:description).pluck(:description).each do |d|
      User.where(description: d).update_all(html_description: BbcodeHelper.emotify(d))
    end
    User.all.group(:bio).pluck(:bio).each do |b|
      User.where(bio: b).update_all(html_bio: BbcodeHelper.emotify(b))
    end
    Album.all.group(:description).pluck(:description).each do |d|
      Album.where(description: d).update_all(html_description: BbcodeHelper.emotify(d))
    end
  end
end

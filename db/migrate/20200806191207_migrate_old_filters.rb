class MigrateOldFilters < ActiveRecord::Migration[5.1]
  def change
    User.all.each do |user|
      user_id = user.id
      tags = TagSubscription.where('user_id = ? AND (hide = true OR spoiler = true)', user_id).pluck(:tag_id, :hide, :spoiler)

      SiteFilter.reset_column_information

      if tags.length > 0
        hide = Tag.where('id IN (?)', tags.filter{|t| t[1]}.map{|t| t[0]}).actual_names.join(',')
        spoiler = Tag.where('id IN (?)', tags.filter{|t| t[2]}.map{|t| t[0]}).actual_names.join(',')
        user.site_filter = SiteFilter.create({
          user_id: user.id,
          name: "#{user.username}'s Everything",
          description: 'Auto-generated by Project Vinyl',
          preferred: false,
          spoiler_tags: spoiler,
          hide_tags: hide
        })
        user.save
      end
    end
  end
end

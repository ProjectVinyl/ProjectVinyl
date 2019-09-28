class ConvertFileStorageTwo < ActiveRecord::Migration[5.1]
  def change
    User.all.find_each do |user|
      mv(Rails.root.join('public', 'banner', "#{user.id}.png"), user.banner_path)
      mv(Rails.root.join('public', 'avatar', "#{user.id}#{user.mime}"), user.avatar_path)
      mv(Rails.root.join('public', 'avatar', "#{user.id}-small#{user.mime}"), user.avatar_path_small)
    end
  end

  def mv(from, to)
    if File.exist?(from)
      FileUtils.mkdir_p(File.dirname(to))
      FileUtils.mv(from, to)
    end
  end
end

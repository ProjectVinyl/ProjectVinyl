class MigrateAvatars < ActiveRecord::Migration
  def change
    User.all.each do |user|
      ext = user.mime ? Mimes.ext(user.mime) : 'png'
      from = Rails.root.join('public', 'avatar', user.id.to_s)
      to = user.avatar_path + ext
      small = user.avatar_path + '-small' + ext
      if File.exist?(from)
        File.rename(from, to)
        user.mime = ext
        Ffmpeg.crop_avatar(to, to)
        Ffmpeg.scale(to, small, 30)
      else
        user.mime = nil
      end
      user.save
    end
  end
end

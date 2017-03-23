class MigrateAvatars < ActiveRecord::Migration
  def change
    User.all.each do |user|
      ext = user.mime ? Mimes.ext(user.mime) : '.png'
      if ext.nil?
        ext = user.mime
      end
      from = Rails.root.join('public', 'avatar', user.id.to_s)
      to = user.avatar_path.to_s + ext
      small = user.avatar_path + '-small' + ext
      if File.exist?(from)
        puts 'mv ' + from.to_s + ' => ' + to.to_s
        File.rename(from, to)
        user.mime = ext
        puts 'exec Fffmpeg.crop_avatar'
        Ffmpeg.crop_avatar(to, to)
        puts 'exec Fffmpeg.scale'
        Ffmpeg.scale(to, small, 30)
      elsif !File.exist?(to)
        user.mime = nil
      end
      user.save
    end
  end
end

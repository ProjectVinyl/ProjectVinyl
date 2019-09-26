class ConvertFileStorage < ActiveRecord::Migration[5.1]
  def change
    Video.all.find_each do |video|
      root = video.storage_root

      mv(Rails.root.join(root, 'stream', "#{video.id}#{video.file || '.mp4'}"), video.video_path)
      mv(Rails.root.join(root, 'stream', "#{video.id}.webm"), video.webm_path)
      mv(Rails.root.join('public', 'cover', "#{video.id}.png"), video.cover_path)
      mv(Rails.root.join('public', 'cover', "#{video.id}-small.png"), video.tiny_cover_path)
    end
  end

  def mv(from, to)
    if File.exist?(from)
      FileUtils.mkdir_p(File.dirname(to))
      FileUtils.mv(from, to)
    end
  end
end

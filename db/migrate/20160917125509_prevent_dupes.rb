class PreventDupes < ActiveRecord::Migration
  def change
    add_column :videos, :checksum, :string, limit: 32
    add_index :videos, :checksum
    Video.reset_column_information
    Video.all.each do |v|
      file = v.video_path
      if File.exist?(file)
        File.open(file, 'rb') do |io|
          v.checksum = Ffmpeg.compute_checksum(io.read)
          v.save
        end
      end
    end
  end
end

class RefactorVideos < ActiveRecord::Migration
  def change
    add_column :videos, :views, :integer, default: 0
    add_column :videos, :processed, :boolean, default: false
    Video.reset_column_information
    Video.all.each do |vid|
      vid.views = 0
      vid.processed = vid.mime.nil? ? false : true
      if vid.mime.nil?
        vid.mime = vid.audio_only ? "audio/mpeg" : "video/mp4"
      end
      vid.file = Rack::Mime::MIME_TYPES.invert[vid.mime]
      vid.save
    end
  end
end

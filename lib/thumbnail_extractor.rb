class ThumbnailExtractor
  SCALE_ONE_THIRTY = 'scale=-1:130'.freeze

  def self.extract_from_image(input, cover_path, thumbnail_path)
    FileUtils.mkdir_p File.dirname(cover_path)
    MultiFileEncoder.encode_multi(nil, input, [], thumbnail_args: {
      full: cover_path,
      small: thumbnail_path
    }) do
      yield if block_given?
    end
  end

  def self.extract_from_video(input, cover_path, thumbnail_path, time)
    MultiFileEncoder.encode_multi(nil, input, [], thumbnail_args: {
      full: cover_path,
      small: thumbnail_path,
      time: Ffmpeg.to_h_m_s_accurate(time)
    }) do
      yield if block_given?
    end
  end
end

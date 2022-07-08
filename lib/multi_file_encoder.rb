
#
# Performs concurrent encoding of multiple files
#
class MultiFileEncoder
  ARGS_BY_FORMAT = {
    webm: %w[-c:v libvpx -crf 10 -b:v 1M -c:a libvorbis],
    mp4: %w[-vcodec libx264 -strict -2]
  }.freeze
  THUMBNAIL_ARGS = {
    full: %w[-vframes 1],
    small: %w[-vframes 1 -vf scale=-1:130]
  }.freeze

  #
  # Encodes multiple files at the same time
  # record = the database object
  # input = the original media file
  # media_files = list of all audio/video files to produce.
  # tile_sheet_path = optional location to place a tile sheet
  # thumbnail_args = {
  #   full - optional path to place the full-sized cover image
  #   small - optional path to place to scaled thumbnail
  #   time - timestamp for when to extract the thumbnails from
  #   force - whether to force the creation of new thumbnails (old ones will be deleted)
  # }
  #
  def self.encode_multi(record, input, media_paths, tile_sheet_path: nil, thumbnail_args: nil)
    temp_paths = media_paths
      .filter{|output| !output.exist? && output.extname != input.extname}
      .map{|output| create_output record, output }
      .filter{|output| !detect_existing output }

    args = ['-i', input]
    temp_paths.each do |output|
      args += output[:args]
      args << output[:from]
      FileUtils.mkdir_p File.dirname(output[:to])
    end

    if !thumbnail_args.nil?
      THUMBNAIL_ARGS.keys
        .filter{|key| !thumbnail_args[key].nil?}
        .map do |key|
          FileUtils.del(thumbnail_args[key]) if thumbnail_args[:force]

          {
            args: THUMBNAIL_ARGS[key],
            path: thumbnail_args[key]
          }
        end
        .filter{|output| !output[:path].exist?}
        .each do |output|
          args += ['-ss', thumbnail_args[:time]] if !thumbnail_args[:time].nil?
          args += output[:args]
          args << output[:path]
        end
    end

    if !tile_sheet_path.nil?
      args += TileSheetEncoder.tile_sheet_args(input, tile_sheet_path)
    end

    if args.length == 2
      yield if block_given?
      return 'Nothing to do'
    end

    Ffmpeg.run_command *args do
      puts "Conversion complete (#{media_paths}), thumbs: #{!thumbnail_args.nil?}, tiles: #{!tile_sheet_path.nil?}"
      temp_paths.each{|output| move_file output[:from], output[:to]}
      yield if block_given?
    end

    return 'Conversion Started'
  end

  private
  def self.create_output(record, output)
    {
      from: Rails.root.join('encoding', record.id.to_s + output.extname),
      to: output,
      args: ARGS_BY_FORMAT[output.extname.sub('.', '').to_sym] || []
    }
  end

  def self.detect_existing(output)
    from = output[:from]
    to = output[:to]

    return false if !from.exist?

    if to.exist? && to.size >= from.size
      FileUtils.remove_entry from
      return true # to exists but is larger
    end

    # to exists but is smaller

    if from.mtime < Time.now.ago(1800)
      move_file output[:from], output[:to]
      return true
    end

    FileUtils.remove_entry from
    false
  end

  def self.move_file(from, to)
    FileUtils.remove_entry to if to.exist?
    FileUtils.mv from, to
  end
end

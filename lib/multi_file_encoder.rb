
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
      args << output[:from].to_s
      FileUtils.mkdir_p File.dirname(output[:to])
      FileUtils.ln_s output[:from], output[:to]
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
          args << output[:path].to_s
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
      temp_paths.each do |output|
        FileUtils.remove_entry output[:to]
        FileUtils.mv output[:from], output[:to], force: true
      end

      yield if block_given?
    end
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
    temp = output[:from]
    return false if !temp.exist?
    
    if temp.mtime > Time.now.ago(1800)
      temp.remove
      return false
    end

    FileUtils.mv output[:from], output[:to], force: true
    true
  end
end

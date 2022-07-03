class TileSheetEncoder
  SHEET_MAX_SIDE = 20
  SHEET_SIZE = SHEET_MAX_SIDE * SHEET_MAX_SIDE

  def self.extract_tile_sheet(record, input, output)
    MultiFileEncoder.encode_multi(record, input, [], tile_sheet_path: output) do
      puts "Sprite Sheet complete (#{output})"
      yield if block_given?
    end
  end

  def self.tile_sheet_args(input, output)
    frame_count = Ffprobe.frames(input) / 20
    rows = SHEET_MAX_SIDE
    if (frame_count > 0 && frame_count <= SHEET_SIZE)
      rows = (frame_count.to_f / SHEET_MAX_SIDE).ceil
    end
    FileUtils.mkdir_p(output)
    ['-vsync', 'vfr', '-q:v', 1, '-vf', "select=not(mod(n\\,20)),scale=-1:50,tile=#{SHEET_MAX_SIDE}x#{rows}", output.to_s + "/sheet_%03d.jpg"]
  end
end


require 'projectvinyl/web/ajax'
require 'projectvinyl/bbc/bbcode'
require 'uri'

module ProjectVinyl
  module Web
    class ThePonyArchive
      ROOT_DIR = 'archive'.freeze
      VIDEO_EXTENSIONS = %w[.mp4 .webm .mkv .mp3].freeze
      SEARCH_PATHS = [
        '/youtube/*$CHANNEL',
        '/eqd_yt',
        '/quickchive',
        '/quickchive/eqd_yt',
        '/quickchive/archivelist',
        '/quickchive/$ARTIST'
      ].freeze

      def self.video_meta(video_id, channel_id: nil)
        find_video_files_of_type(video_id, channel_id, 'info.json')
          .take(1)
          .map(&ThePonyArchive.method(:create_entry))
          .first || { error: "TPA [#{video_id}] Item not found" }
      end

      def self.create_entry(file_path)
        file_path = Pathname.new(file_path).expand_path
        metadata = JSON.parse file_path.read, symbolize_names: true
        primary_video_source = file_path.parent + Pathname.new(metadata[:_filename]).basename
        description_path = file_path.sub('.info.json', '.description')

        metadata[:description] = description_path.read if description_path.exist?

        {
          file_paths: {
            info: file_path,
            description: description_path,
            video: primary_video_source,
            thumbnail: file_path.sub('.info.json', Pathname.new(metadata[:thumbnails][0][:url]).extname),
            additional_sources:
              (
                [ primary_video_source ] | VIDEO_EXTENSIONS.map{|ext| primary_video_source.sub('.' + metadata[:ext], ext)}
              )
                .filter(&File.method(:exists?))
                .uniq
          },
          metadata: metadata
        }
      end

      def self.find_video_files_of_type(video_id, channel_id, type)
        paths = SEARCH_PATHS.map{|dir| dir.sub('$CHANNEL', channel_id || '')}
        return probe_archive_directories(paths, "*#{video_id}.#{type}")
      end

      def self.probe_archive_directories(paths, pattern)
        puts "Input paths: #{paths}"
        paths.each do |dir|
          puts "GLOB: #{ROOT_DIR}#{dir}/#{pattern}"
          matches = Dir.glob("#{ROOT_DIR}#{dir}/#{pattern}")
          return matches if matches.length > 0
        end
        
        []
      end
    end
  end
end

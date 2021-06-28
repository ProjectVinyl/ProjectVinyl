module Albums
  module AlbumLike
    extend ActiveSupport::Concern
    included do
      extend Forwardable
      def_delegator :video_set, :virtual?
    end

    def play_all_path
      vid_id = album_items.order(:index).limit(1).pluck(:video_id).first
      return nil if vid_id.nil?
      "/#{vid_id}?list=#{id}&index=0"
    end
  end
end

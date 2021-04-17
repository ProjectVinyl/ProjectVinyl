module Albums
  module Compat
    extend ActiveSupport::Concern
    included do
      extend Forwardable
      def_delegator :video_set, :sample, :sample_videos
      def_delegator :video_set, :add, :add_item
      def_delegator :video_set, :toggle, :toggle
      def_delegator :video_set, :all, :all_items
      def_delegator :video_set, :current_index, :current_index
      def_delegator :video_set, :current, :current
      def_delegator :video_set, :next, :next_video
      def_delegator :video_set, :previous, :previous_video
      def_delegator :video_set, :virtual?, :virtual?
    end
  end
end

module Albums
  module Album
    extend ActiveSupport::Concern
    included do
      extend Forwardable
      def_delegator :video_set, :virtual?
    end
  end
end

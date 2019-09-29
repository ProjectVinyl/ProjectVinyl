module Assets
  module Users
    class ThumbsController < BaseAssetsController
      def show
        redirect_to '/images/default-avatar.png'
      end
    end
  end
end

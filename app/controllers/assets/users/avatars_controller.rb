module Assets
  module Users
    class AvatarsController < BaseAssetsController
      def show
        redirect_to '/images/default-avatar.png'
      end
    end
  end
end

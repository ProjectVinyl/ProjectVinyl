module Assets
  module Users
    class BannersController < BaseAssetsController
      def show
        redirect_to '/images/new-banner.jpg'
      end
    end
  end
end

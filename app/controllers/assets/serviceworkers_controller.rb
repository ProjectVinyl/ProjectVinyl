module Assets
  class ServiceworkersController < BaseAssetsController
    def show
      serve_asset('serviceworker.js', 'application/javascript')
    end
  end
end
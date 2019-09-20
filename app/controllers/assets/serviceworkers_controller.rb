module Assets
  class ServiceworkersController < ApplicationController
    include Assetable

    def show
      serve_asset('serviceworker.js', 'application/javascript')
    end
  end
end
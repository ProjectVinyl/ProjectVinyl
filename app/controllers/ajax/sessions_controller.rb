module Ajax
  class SessionsController < ApplicationController
    def login
      render partial: "devise/sessions/new"
    end
  end
end

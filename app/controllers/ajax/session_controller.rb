module Ajax
  class SessionController < ApplicationController
    def login
      render partial: "devise/sessions/new"
    end
  end
end

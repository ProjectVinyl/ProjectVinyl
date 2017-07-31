module Ajax
  class LoginController < ApplicationController
    def login
      render partial: "devise/sessions/new"
    end
  end
end

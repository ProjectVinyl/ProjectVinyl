module Admin
  module Forum
    module Threads
      class PinsController < BaseThreadsController
        def update
          toggle_action do |thread|
            thread.pinned = !thread.pinned
          end
        end
      end
    end
  end
end

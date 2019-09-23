module Admin
  module Forum
    module Threads
      class LocksController < BaseThreadsController
        def update
          toggle_action do |thread|
            thread.locked = !thread.locked
          end
        end
      end
    end
  end
end

require 'elasticsearch/model'

module Indexable
  extend ActiveSupport::Concern
	
  included do
    include Elasticsearch::Model
		
    after_commit(on: :create) do
			distrust do
				__elasticsearch__.index_document
			end
    end

    after_commit(on: :destroy) do
      distrust do
        __elasticsearch__.delete_document
      end
    end
  end
	
  def update_index(defer: true)
    distrust do
      return IndexUpdateJob.perform_later(self.class.to_s, id) if defer
      __elasticsearch__.index_document
    end
  end
  
  def distrust
    yield
  rescue Elasticsearch::Transport::Transport::Errors::Forbidden => e
    logger.warn e
  rescue Faraday::Error::ConnectionFailed => e
    logger.fatal e
  end
end

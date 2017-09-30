require 'elasticsearch/model'

module Indexable
  extend ActiveSupport::Concern
	
  included do
    include Elasticsearch::Model
		
    after_commit(on: :create) do
			begin
				__elasticsearch__.index_document
			rescue Faraday::Error::ConnectionFailed => e
				logger.fatal e
			end
    end

    after_commit(on: :destroy) do
      __elasticsearch__.delete_document
    end
  end
	
  def update_index(defer: true)
		begin
			if defer
				IndexUpdateJob.perform_later(self.class.to_s, id)
			else
				__elasticsearch__.index_document
			end
		rescue Faraday::Error::ConnectionFailed => e
			logger.fatal e
		end
  end
end

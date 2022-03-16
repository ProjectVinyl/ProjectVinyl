require 'elasticsearch/model'

module Indexable
  extend ActiveSupport::Concern
	
  included do
    include Elasticsearch::Model

    after_commit(on: :create) do
      update_index(defer: false)
    end

    after_commit(on: :destroy) do
      distrust do
        __elasticsearch__.delete_document
      end
    end

    clazz = self.to_s
    scope :update_index, ->(defer: true){
      return UpdateIndexJob.perform_later(clazz, pluck(:id)) if defer
      each{|i| i.__elasticsearch__.index_document }
    }
  end
	
  def update_index(defer: true)
    distrust do
      return UpdateIndexJob.perform_later(self.class.to_s, [id]) if defer
      __elasticsearch__.index_document
    end
  end
  
  def distrust
    yield
  rescue Elasticsearch::Transport::Transport::Errors::Forbidden => e
    logger.warn e.message
  rescue IO::EINPROGRESSWaitWritable => e
    logger.fatal e
  rescue Faraday::ConnectionFailed => e
    logger.fatal e
  end
end

require 'elasticsearch/model'

module Indexable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    after_commit(on: :create) do
      __elasticsearch__.index_document
    end

    after_commit(on: :destroy) do
      __elasticsearch__.delete_document
    end
  end

  def update_index(defer: true)
    if defer
      IndexUpdateJob.perform_later(self.class.to_s, id)
    else
      __elasticsearch__.index_document
    end
  end
end
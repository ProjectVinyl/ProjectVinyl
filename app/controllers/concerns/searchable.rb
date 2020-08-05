require 'projectvinyl/search/search'
require 'projectvinyl/search/active_record'

module Searchable
  extend ActiveSupport::Concern

  included do
    def self.configure_ordering(orders = [], params = {})
      qt = 'qt'
      if params.key?(:only)
        before_action only: params[:only] do
          @orderings = orders
        end
      else
        before_action do
          @orderings = orders
        end
      end

      define_method :query_term do
        qt
      end
      qt = params[:query_term] if params[:query_term]
    end
  end
  
  def read_search_params(params)
    @query_term = query_term
    @page = (params[:page] || 0).to_i
    @query = (params[@query_term] || '').strip
    @order = (params[:order] || 0).to_i
    @orderby = (params[:orderby] || 0).to_i
    @ascending = @order == 0
    @data = URI.encode_www_form({
      @query_term => @query,
      :orderby => @orderby
    })
    @ordering_labels = @orderings.map {|a| a.to_s.titlecase}
  end

  def order_field
    @orderings[@orderby]
  end

  def filtered?
    @query.length > 0
  end
  
end

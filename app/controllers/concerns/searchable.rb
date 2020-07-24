
module Searchable
  extend ActiveSupport::Concern

  included do
    @@query_term = 'qt'
    def self.configure_ordering(orders = [], params = {})
      @@orders = orders
      define_method :configured_orderings do
        return @@orders
      end
      params[:query_term] = qt if params[:query_term]
    end
  end
  
  def read_search_params(params)
    @query_term = @@query_term
    @query = (params[@query_term] || '').strip
    @order = (params[:order] || 0).to_i
    @orderby = (params[:orderby] || 0).to_i
    @ascending = @order == 0
    @data = URI.encode_www_form({
      @query_term => @query,
      :orderby => @orderby
    })
    @orderings = configured_orderings
  end

  def order_field
    configured_orderings[@order]
  end
  
  def filtered?
    @query.length > 0
  end
  
end

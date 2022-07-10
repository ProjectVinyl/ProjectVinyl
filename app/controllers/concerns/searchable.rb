require 'projectvinyl/search/search'
require 'projectvinyl/search/active_record'

module Searchable
  extend ActiveSupport::Concern

  included do
    def self.configure_ordering(orders = [], params = {})
      sa = params[:search_action] || ''
      qt = params[:query_term] || 'qt'

      labels_syms = orders.map {|a| [].is_a?(a.class) ? a[0] : a}
      orders = {
        fields: orders.map {|a| [].is_a?(a.class) ? a[1] : a},
        labels_syms: labels_syms,
        labels: labels_syms.map {|a| a.to_s.titlecase}
      }

      if params.key?(:only)
        before_action only: params[:only] do
          before_search(orders, params)
        end
      else
        before_action do
          before_search(orders, params)
        end
      end
    end
  end

  def before_search(orders, params)
    @ordering = orders
    @ordering_labels = @ordering[:labels]
    @sa = params[:search_action] || ''
    @qt = params[:query_term] || 'qt'
    @sa = self.send(@sa) if !''.is_a?(@sa.class)
  end

  def read_search_params(params, default_order: 0)
    @query_term = query_term
    @page = (params[:page] || 0).to_i
    @query = (params[@query_term] || '').strip
    @order = (params[:order] || default_order).to_i
    @orderby = (params[:orderby] || 0).to_i
    @ascending = @order == 0
    @data = URI.encode_www_form({
      @query_term => @query,
      :orderby => @orderby
    })
  end

  def order_sym
    @ordering[:labels_syms][@orderby]
  end

  def order_field
    @ordering[:fields][@orderby]
  end

  def filtered?
    @query.length > 0
  end

  def query_term
    @qt
  end
end

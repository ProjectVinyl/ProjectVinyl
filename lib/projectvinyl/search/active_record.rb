require 'projectvinyl/search/exceptable'
require 'projectvinyl/search/query_wrapper'

module ProjectVinyl
  module Search
    class ActiveRecord
      include Exceptable

      def initialize(table, &block)
        @execute_callback = block
        @table = table
        @initial = { query: { bool: {} }, sort: [] }
        @direction = :asc
        @sort_fields = []
      end

      def order(*params)
        __clear!
        @sort_fields = params
        params = params.map do |field|
          { field => { order: @direction } }
        end

        sort params
      end

      def sort(orderings)
        @initial[:sort] = orderings
        self
      end

      def reverse_order
        __clear!
        @direction = @direction == :asc ? :desc : :asc
        order *@sort_fields
      end

      def offset(offset)
        __clear!
        @initial[:from] = offset
      end

      def limit(limit)
        __clear!
        @initial[:size] = limit
        self
      end

      def must(term)
        __bucket(:must) << term
        self
      end

      def must_not(term)
        __bucket(:must_not) << term
        self
      end

      def filter(term)
        __bucket(:filter) << term
        self
      end

      def where(params)
        params.keys.each do |key|
          filter({ term: { key => params[key] } })
        end

        self
      end

      def where_not(params)
        params.keys.each do |key|
          must_not({ term: { key => params[key] } })
        end

        self
      end

      def ids
        __execute.ids
      end

      def total
        __execute.total
      end

      def count
        __execute.count
      end

      def records
        @table.none if @exception
        @records ||= __execute.records
      end

      def random
        __clear!

        @search = __execute!({
          size: @initial[:size],
          query: {
            function_score: {
              query: @initial[:query],
              functions: [
                random_score: {}
              ]
            }
          }
        })

        records
      end

      def paginate(page_number, page_size, &block)
        __clear!

        offset [0, page_number].max * page_size
        limit page_size

        if page_number < 0
          page_number = 0
          @search = __execute! @initial

          return __paginate! page_size, page_number, block if total <= page_size

          page_number = (total / page_size).floor
          offset page_number * page_size
        end

        @search = __execute! @initial

        if count == 0 && total > 0 && page_number > 0
          page_number = (total / page_size).floor
          offset page_number * page_size
          @search = __execute! @initial
        end

        __paginate! page_size, page_number, block
      end

      private
      def __paginate!(page_size, page_number, block)
        recs = block ? block.call(records) : records
        __ready! Pagination.new(recs, page_size, (total / page_size).floor, page_number, total).excepted(self)
      end

      def __clear!
        @search = nil
        @records = nil
      end

      def __ready!(result)
        @execute_callback.call(self) if @execute_callback
        result
      end

      def __execute!(params)
        QueryWrapper.new(self, @table, params)
      end

      def __execute
        return @search if @search
        @search = __execute! @initial
        __ready! @search
      end

      def __query
        @initial[:query]
      end

      def __bucket(key)
        __clear!
        __query[:bool][key] = [] if !__query[:bool].key?(key)
        __query[:bool][key]
      end
    end
  end
end

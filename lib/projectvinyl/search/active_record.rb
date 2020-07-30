module ProjectVinyl
  module Search
    class ActiveRecord
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
        @initial[:sort] = params.map do |field|
          { field => { order: @direction } }
        end

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
        __execute.map(&:id).map(&:to_i)
      end

      def records
        @records ||= __execute.records
      end

      def paginate(page_number, page_size, &block)
        offset [0, page_number].max * page_size
        limit page_size

        if page_number < 0
          page_number = 0
          @search = @table.search(@initial)

          return __paginate! page_size, page_number, block if @search.results.total <= page_size

          page_number = (@search.results.total / page_size).floor
          offset page_number * page_size
        end

        @search = @table.search(@initial)

        if @search.count == 0 && @search.results.total > 0 && page_number > 0
          page_number = (@search.results.total / page_size).floor
          offset page_number * page_size
          @search = @table.search(@initial, page_size)
        end

        __paginate! page_size, page_number, block
      end

      private
      def __paginate!(page_size, page_number, block)
        recs = block ? block.call(records) : records
        Pagination.new(recs, page_size, (@search.results.total / page_size).floor, page_number, false, @search.results.total)
      end

      def __clear!
        @results = nil
        @records = nil
      end

      def __ready!(result)
        @execute_callback.call(self) if @execute_callback
        result
      end

      def __execute
        return @results if @results
        @results = @table.search(@initial)
        __ready! @results
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

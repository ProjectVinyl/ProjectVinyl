module ProjectVinyl
  module ElasticSearch
    module ActiveRecord
      class Selector
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

        private
        def __clear!
          @results = nil
          @records = nil
        end

        def __execute
          return @results if @results
          @results = @table.search(@initial)
          @execute_callback.call(self) if @execute_callback
          @results
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
end

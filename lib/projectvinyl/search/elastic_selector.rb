require 'projectvinyl/search/search'

module ProjectVinyl
  # TODO: Pending removal.
  module Search
    class ElasticSelector
      attr_accessor :ordering
      attr_reader :table

      def initialize(sender, search_terms, index_params)
        @user = sender
        @index_params = index_params
        @search_terms = search_terms.downcase
        @elastic = nil
        @exception = nil
        @offset = 0
        @table = index_params.table
        @randomized = false
        @ordering = []
      end

      def randomized(limit)
        query(0, limit)
        @randomized = true
        self
      end

      def query(page, limit)
        @page = page
        @limit = limit
        self
      end

      def offset(off)
        @offset = off
        self
      end

      def order_by(order)
        @ordering = [ { order => {order: 'asc' }} ]
        self
      end

      def following(obj)
        @search_after = obj.created_at.to_i

        self
      end

      def exec
        @page = 0 if @page.nil?

        params = {
          from: @offset + @limit * @page,
          size: @limit,
          query: add_required_params(__elastic.to_hash)
        }

        if !@ordering.empty? && !@randomized
          params[:sort] = @ordering
        end

        if @page < 0
          @page = 0
          params[:from] = 0
          @search = @table.search(params)

          return self if @search.results.total <= @limit

          @page = (@search.results.total / @limit).floor
          params[:from] = @page * @limit
        end

        @search = @table.search(params)

        if @search.count == 0 && @search.results.total > 0 && @page > 0
          @page = (@search.results.total / @limit).floor
          params[:from] = @page * @limit
          @search = @table.search(params)
        end

        self
      rescue Faraday::ConnectionFailed => e
        @exception = e

        self
      rescue => e
        @exception = e
        puts "Exception raised #{e}"
        puts "Backtrace:\n\t#{e.backtrace[0..8].join("\n\t")}"

        self
      end

      def records
        return @table.none if exception
        return @search.records.includes(:tags).with_likes(@user) if @table == Video
        return @search.records.includes(:videos, :tag_type) if @table == Tag
        @search.records
      end

      attr_reader :page

      def exception
        @exception || __elastic.exception
      end
      
      def exception_type
        __elastic.exception_type
      end

      def lexer_error?
        __elastic.lexer_error?
      end

      def input_error?
        __elastic.input_error?
      end

      def page_offset_start
        @page * page_size
      end

      def page_offset_end
        [count, page_offset_start + page_size].min
      end

      def page_size
        @limit
      end

      def pages
        (count / @limit).floor
      end

      def count
        @exception ? 0 : @search.results.total
      end

      def length
        count
      end

      def __elastic!
        Search.interpret(@search_terms, @index_params, @user)
      end

      def __elastic
        @elastic = __elastic! if !@elastic
        @elastic
      end

      def tags
        Tag.by_names(__elastic.tags)
      end
      
      private
      def add_required_params(query)
        return query if @table != Video

        if !query.key?(:bool)
          query = { term: { hidden: false } }
        else
          query[:bool][:must] = [] if !query[:bool].key?(:must)
          query[:bool][:must] << { term: { hidden: false } } if !@elastic.uses(:hidden)

          if !@search_after.nil?
            query[:bool][:must] << {
              range: {
                created_at: {
                  gte: @search_after
                }
              }
            }
          end
        end

        if @randomized
          query = {
            function_score: {
              query: query,
              functions: [
                random_score: {}
              ]
            }
          }
        end

        query
      end
    end
  end
end

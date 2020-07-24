require 'projectvinyl/elasticsearch/op'
require 'projectvinyl/elasticsearch/elastic_builder'
require 'projectvinyl/elasticsearch/order'

module ProjectVinyl
  module ElasticSearch
    class ElasticSelector
      def initialize(sender, search_terms)
        @user = sender
        @opset = Op.load_ops(search_terms.downcase)
        @elastic = nil
        @exception = nil
        @lexer_error = 0
        @offset = 0
        @type = "unknown"
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

      def videos
        @type = 'video'
        self
      end

      def users
        @type = 'user'
        self
      end

      def order_by(order)
        @ordering = [ { order => {order: 'asc' }} ]
        self
      end

      def ordering
        @ordering
      end

      def order(session, ordering, ascending)
        @ordering = Order.parse(@type, session, ordering, ascending)
        self
      end

      def add_required_params(query)
        return query if @type != 'video'

        if !query.key?(:bool)
          query = { term: { hidden: false } }
        else
          if !query[:bool].key?(:must)
            query[:bool][:must] = []
          end

          if !@elastic.uses(:hidden)
            query[:bool][:must] << { term: { hidden: false } }
          end

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
          @search = table.search(params)

          return self if @search.results.total <= @limit

          @page = (@search.results.total / @limit).floor
          params[:from] = @page * @limit
        end

        @search = table.search(params)

        if @search.count == 0 && @search.results.total > 0 && @page > 0
          @page = (@search.results.total / @limit).floor
          params[:from] = @page * @limit
          @search = table.search(params)
        end

        self
      rescue InputError => e
        @exception = e
        @lexer_error = 1
        self
      rescue LexerError => e
        @exception = e
        @lexer_error = 2
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

      def sanitize(arguments)
        Tag.sanitize_sql(arguments)
      end

      def records
        if @exception
          return table.none
        end

        if @type == 'user'
          return @search.records
        end

        @search.records.includes(:tags).with_likes(@user)
      end

      attr_reader :page

      def error
        @exception
      end

      def lexer_error?
        @lexer_error == 2
      end

      def input_error?
        @lexer_error == 1
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

      def table
        @type == 'user' ? User : Video
      end

      def __elastic!
        ElasticBuilder.interpret_opset(@type, @opset, @user)
      end

      def __elastic
        @elastic = __elastic! if !@elastic
        @elastic
      end

      def tags
        Tag.get_tags(__elastic.tags)
      end
    end
  end
end

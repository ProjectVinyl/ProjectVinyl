require 'projectvinyl/search/op'
require 'projectvinyl/elasticsearch/elastic_builder'

module ProjectVinyl
  module ElasticSearch
    class ElasticSelector
      def initialize(sender, search_terms)
        @user = sender
        @opset = ProjectVinyl::Search::Op.load_ops(search_terms.downcase)
        @elastic = nil
        @exception = nil
        @lexer_error = false
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
      
      def order_by(ordering)
        @ascending = true
        @ordering = [ordering]
        self
      end

      def random_order(session, _ordering, possibles)
        if @page == 0
          session[:random_ordering] = possibles[rand(0..possibles.length)].to_s + ';' + possibles[rand(0..possibles.length)].to_s
        end
        session[:random_ordering].split(';')
      end

      def ordering
        direction = @ascending ? 'asc' : 'desc'
        @ordering.map do |i|
          { i => { order: direction } }
        end
      end

      def order(session, ordering, ascending)
        @ascending = ascending
        if ordering == 5
          @ordering = []
          return self
        end
        @ordering = [:created_at]
        if @type == 'video'
          if ordering == 4
            @ordering = random_order(session, ordering, %i[length created_at updated_at score])
            return self
          end
          @ordering << :updated_at
          if ordering == 2
            @ordering.unshift(:score)
          elsif ordering == 3
            @ordering.unshift(:length)
          end
        elsif @type == 'user'
          if ordering == 4
            @ordering = random_order(session, ordering, %i[created_at updated_at])
            return self
          end
          if ordering < 4
            @ordering = %i[created_at updated_at]
          else
            @ordering = %i[created_at updated_at]
          end
        end
        self
      end

      def add_required_params(query)
        if @type != 'video'
          return query
        end

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
        @elastic = ElasticBuilder.interpret_opset(@type, @opset, @user) if !@elastic

        params = {
          from: @offset + @limit * @page,
          size: @limit,
          query: add_required_params(@elastic.to_hash)
        }

        if !ordering.empty? && !@randomized
          params[:sort] = ordering
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
      rescue ProjectVinyl::Search::LexerError => e
        @exception = e
        @lexer_error = true
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
        
        @records || (@records = Video.includes(:tags).where('videos.id IN (?)', @search.records.ids).with_likes(@user))
      end

      attr_reader :page
      
      def error
        @exception
      end
      
      def lexer_error?
        @lexer_error
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

      def tags
        if !@elastic
          @elastic = ElasticBuilder.interpret_opset(@type, @opset, @user)
        end
        Tag.get_tags(@elastic.tags)
      end
    end
  end
end

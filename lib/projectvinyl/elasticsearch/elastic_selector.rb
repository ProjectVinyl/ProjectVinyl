require 'projectvinyl/search/op'
require 'projectvinyl/elasticsearch/elastic_builder'

module ProjectVinyl
  module ElasticSearch
    class ElasticSelector
      def initialize(sender, search_terms)
        @user = sender
        @opset = ProjectVinyl::Search::Op.load_ops(search_terms.downcase)
        @elastic = nil
        @type = "unknown"
        @ordering = []
      end

      def query(page, limit)
        @page = page
        @limit = limit
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
        return query if @type != 'video'
        return { term: { hidden: false } } if !query.key?(:bool)
        query[:bool][:must] = [] if !query[:bool].key?(:must)
        if !@elastic.uses(:hidden)
          query[:bool][:must] << { term: { hidden: false } }
        end
        query
      end

      def exec
        if !@elastic
          @elastic = ElasticBuilder.interpret_opset(@type, @opset, @user)
        end
        @page = 0 if @page.nil?
        params = {
          from: @limit * @page,
          size: @limit,
          query: add_required_params(@elastic.to_hash)
        }
        params[:sort] = ordering if !ordering.empty?
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
      end

      def sanitize(arguments)
        Tag.sanitize_sql(arguments)
      end

      def records
        if @type == 'user'
          return @search.records
        end
        
        @records || (@records = Video.includes(:tags).where('`videos`.id IN (?)', @search.records.ids).with_likes(@user))
      end

      attr_reader :page

      def page_size
        @limit
      end

      def pages
        (@search.results.total / @limit).floor
      end

      def count
        @search.results.total
      end

      def length
        @search.results.total
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

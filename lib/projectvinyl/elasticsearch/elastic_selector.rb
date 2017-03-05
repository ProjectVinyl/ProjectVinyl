require 'projectvinyl/search/op'
require 'projectvinyl/elasticsearch/elastic_builder'

module ProjectVinyl
  module ElasticSearch
    class ElasticSelector
      
      def initialize(sender, search_terms)
        @user = sender
        @opset = ProjectVinyl::Search::Op.loadOPS(search_terms.downcase)
        @type = "unknown"
      end
      
      def query(page, limit)
        @page = page
        @limit = limit
        return self
      end
      
      def videos
        @type = "video"
        return self
      end
      
      def users
        @type = "user"
        return self
      end
      
      def order_by(ordering)
        @ordering = ordering
        return self
      end
      
      def offset(off)
        @offset = off
        return self
      end
      
      def random_order(session, ordering, possibles)
        if @page == 0
            session[:random_ordering] = possibles[rand(0..possibles.length)].to_s + ';' + possibles[rand(0..possibles.length)].to_s
          end
          return session[:random_ordering].split(';')
      end
      
      def ordering
        direction = @ascending ? 'asc' : 'desc'
        @ordering.map do |i|
          {i => {order: direction}}
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
            @ordering = random_order(session, ordering, [:length,:created_at,:updated_at,:score])
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
            @ordering = random_order(session, ordering, [:username,:created_at,:updated_at])
            return self
          end
          if ordering < 4
            @ordering = [:username, :created_at, :updated_at]
          else
            @ordering = [:username]
          end
        end
        return self
      end
      
      def __exec(params)
        if @type == 'video'
          return Video.search(params)
        end
        return User.search(params)
      end
      
      def add_required_params(query)
        if !query.key?(:bool)
          return {term: { hidden: false }}
        end
        if !query[:bool].key?(:must)
          query[:bool][:must] = []
        end
        query[:bool][:must] << {term: {hidden: false }}
        return query
      end
      
      def exec()
        elastic = ElasticBuilder.interpret_opset(@type, @opset)
        if @page.nil?
          @page = 0;
        end
        if @page < 0
          @page = (@type == 'user' ? User : Video).count / @limit
        end
        params = {
          from: @limit * @page,
          size: @limit,
          query: add_required_params(elastic.to_hash)
        }
        if ordering.length > 0
          params[:sort] = ordering
        end
        @search = __exec(params)
        if @search.count == 0 && @search.results.total > 0 && @page > 0
          @page = (@search.results.total / @limit).floor - 1
          params[:from] = @page * @limit
          @search = __exec(params)
        end
        return self
      end
      
      def sanitize(arguments)
        return Tag.sanitize_sql(arguments)
      end
      
      def records
        @search.records
      end
      
      def page
        @page
      end
      
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
    end
  end
end

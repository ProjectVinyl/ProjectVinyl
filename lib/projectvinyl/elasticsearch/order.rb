module ProjectVinyl
  module ElasticSearch
    class Order
      DATE = 0
      RATING = 1
      HEAT = 2
      LENGTH = 3
      RANDOM = 4
      RELEVANCE = 5

      BY_AUTO = [].freeze
      BY_DATE = %i[created_at updated_at].freeze

      ORDER_LOOKUP = {
        video: [
          BY_DATE,
                      %i[score created_at updated_at],
                 %i[heat score created_at updated_at],
                     %i[length created_at updated_at],
          %i[heat score length created_at updated_at],
          BY_AUTO
        ],
        user: [ BY_DATE, BY_DATE, BY_DATE, BY_DATE, BY_DATE, BY_AUTO ]
      }.freeze

      def self.random_order(session, possibles)
        if @page == 0
          session[:random_ordering] = possibles[rand(0..possibles.length)].to_s + ';' + possibles[rand(0..possibles.length)].to_s
        end
        session[:random_ordering].split(';')
      end

      def self.parse(type, session, ordering, ascending)
        direction = ascending ? 'asc' : 'desc'
        __parse(type, session, ordering).map do |i|
          { i => { order: direction } }
        end
      end

      def self.__parse(type, session, ordering)
        if (lookup = ORDER_LOOKUP[type.to_sym])
          return random_order(session, lookup[ordering]) if ordering == RANDOM
          return lookup[ordering]
        end

        BY_DATE
      end
    end
  end
end

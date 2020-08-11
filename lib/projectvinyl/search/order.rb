module ProjectVinyl
  module Search
    class Order
      DATE = 0
      RATING = 1
      HEAT = 2
      LENGTH = 3
      RANDOM = 4
      RELEVANCE = 5

      BY_DATE = %i[created_at updated_at].freeze

      ORDER_LOOKUP = {
        video: [
          BY_DATE,
                                   %i[score created_at updated_at],
                      %i[wilson_lower_bound created_at updated_at],
                              %i[heat score created_at updated_at],
                                  %i[length created_at updated_at],
          %i[wilson_score heat score length created_at updated_at],
          []
        ]
      }.freeze

      def self.random_order(session, possibles)
        session[:random_ordering] = possibles[rand(0..possibles.length)].to_s + ';' + possibles[rand(0..possibles.length)].to_s if @page == 0
        session[:random_ordering].split(';')
      end

      def self.parse(type, session, ordering, ascending)
        direction = ascending ? 'asc' : 'desc'
        fields(type, session, ordering).map{|i| { i => { order: direction } } }
      end

      def self.fields(type, session, ordering)
        if (lookup = ORDER_LOOKUP[type.to_sym])
          return random_order(session, lookup[ordering]) if ordering == RANDOM
          return lookup[ordering]
        end

        BY_DATE
      end
    end
  end
end

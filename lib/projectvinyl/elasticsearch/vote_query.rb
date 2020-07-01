require 'projectvinyl/elasticsearch/op'

module ProjectVinyl
  module ElasticSearch
    class VoteQuery
      def initialize(owner)
        @owner = owner
        @likes = []
        @dislikes = []
        @dirty = false
      end

      def record(op, opset, sender)
        user = opset.shift
        if sender
          if user == 'nil'
            user = sender.id
          elsif Op.is?(user)
            user = sender.id
          else
            return if !sender.is_staff?
            @owner.root.cache_user(user)
          end

          if op == Op::VOTE_U
            @likes << user
          else
            @dislikes << user
          end
          @dirty = true
        end
      end

      attr_reader :dirty

      def to_hash
        result = []
        @likes.each do |like|
          if s = @owner.user_id_for(like)
            result << { term: { likes: s } }
          end
        end
        @dislikes.each do |dislike|
          if s = @owner.user_id_for(dislike)
            result << { term: { dislikes: s } }
          end
        end
        result
      end
    end
  end
end

require 'projectvinyl/search/op'

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
          elsif ProjectVinyl::Search::Op.is?(user)
            user = sender.id
          else
            if !sender.is_staff?
              return
            end
            @owner.root.cache_user(user)
          end
          
          if op == ProjectVinyl::Search::Op::VOTE_U
            @likes << user
          else
            @dislikes << user
          end
          @dirty = true
        end
      end
      
      def dirty
        @dirty
      end
      
      def to_hash
        result = []
        @likes.each do |like|
          if s = @owner.user_id_for(like)
            result << { term: {likes: s } }
          end
        end
        @dislikes.each do |dislike|
          if s = @owner.user_id_for(dislike)
            result << { term: {dislikes: s } }
          end
        end
        return result
      end
    end
  end
end
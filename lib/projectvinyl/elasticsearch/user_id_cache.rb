module ProjectVinyl
  module ElasticSearch
    class UserIdCache
      def initialize()
        @user_ids_cache = nil
        @users = []
      end

      def cache(user)
        @users << user
      end

      def read_user_id(opset, op, parameter, sender)
        data = opset.shift_data(op, parameter)
        data = data.strip
        return sender.id if sender && data == 'nil'
        cache(data) if data
        data
      end

      def id_for(username)
        return username if 1.is_a?(username.class)

        id = username.to_i
        return id if id.to_s == username

        username = username.downcase
        if !@users.empty? && @user_ids_cache.nil?
          @user_ids_cache = {}
          User.where('LOWER(username) IN (?)', @users).pluck(:id, :username).each do |u|
            @user_ids_cache[u[1].downcase] = u[0]
          end
        end
        return @user_ids_cache[username] if @user_ids_cache.key?(username)
      end
    end
  end
end

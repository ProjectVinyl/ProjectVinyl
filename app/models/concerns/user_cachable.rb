module UserCachable
  extend ActiveSupport::Concern

  included do
    # TODO: Old rails version
    if (!respond_to?(:cache_key_with_version))
      def cache_key_with_version
        cache_key
      end
    end
  end

  def user_role_suffex(user)
    if user != true && user
      return '/user_role_' + user.role.to_s
    end

    ''
  end

  def cache_key_with_user(user)
    cache_key_with_version + user_role_suffex(user)
  end
end

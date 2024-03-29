module UserCachable
  extend ActiveSupport::Concern

  included do
    # TODO: Old rails version
    if (!respond_to?(:cache_key_with_version))
      def cache_key_with_version
        cache_key
      end
    end

    def self.cache_key_with_user(user, *rest)
      "#{self.table_name}_#{UserCachable.user_role_suffex(user)}_#{rest.join('_')}"
    end
  end

  def self.user_role_suffex(user)
    return '/user_role_' + user.role.to_s if user != true && user
    ''
  end

  def cache_key_with_user(user, *rest)
    "#{cache_key}_#{UserCachable.user_role_suffex(user)}_#{rest.join('_')}"
  end
end

module Prefable
  def prefs_cache
    @prefs_cache || (@prefs_cache = Preferences.new(self))
  end

  def options
    result = self.public_send(options_source)
    if result.blank?
      self.update_prefs_column(default_options).save
      return self.public_send(options_source)
    end
    dirty = false
    default_options.keys.each do |key|
      if !result.key?(key)
        result[key] = default_options[key]
        dirty = true
      end
    end
    self.update_prefs_column(result).save if dirty
    result
  end

  def option(key)
    if default_options.key?(key)
      if (opts = options) && opts.key?(key)
        return opts[key]
      end
      default_options[key]
    end
  end

  def set_option(key, val)
    key = key.to_sym
    if default_options.key?(key)
      ops = options
      if default_options[key] == true || default_options[key] == false
        if !(val == true || val == false)
          val = val.downcase
          val = val == 'true' || val == '1'
        end
        ops[key] = val
      else
        ops[key] = val
      end
      self.update_prefs_column(ops)
    end
  end

  class Preferences
    def initialize(owner)
      @owner = owner
      owner.options.keys.each do |key|
        self.define_singleton_method key.to_sym do
          return @owner.option(key)
        end
        self.define_singleton_method (key.to_s + '=').to_sym do |v|
          return @owner.set_option(key, v)
        end
      end
    end

    def each
      options = @owner.options
      options.keys.each do |key|
        yield(key, options[key])
      end
    end

    def save(hash)
      hash.keys.each do |key|
        @owner.set_option(key, hash[key])
      end
      @owner.save
    end
  end

  def update_prefs_column(hash)
    self.public_send((options_source.to_s + '=').to_sym, hash)
    self
  end
end

module ActiveRecord
  class Base
    def self.prefs(as, hash = {})
      include Prefable
      @@default_options = hash
      @@options_source = as
      serialize @@options_source.to_sym, Hash

      define_method :default_options do
        @@default_options
      end
      define_method :options_source do
        @@options_source
      end

      hash.each do |key,value|
        meth_name = (key.to_s + '?').to_sym
        define_method meth_name do
          option key
        end
      end
    end
  end
end

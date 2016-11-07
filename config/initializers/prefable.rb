module Prefable
  def prefs_cache
    @prefs_cache || (@prefs_cache = Preferences.new(self))
  end
  
  def options
    result = self.public_send(options_source)
    if !result || result.empty?
      self.public_send((options_source.to_s + '=').to_sym, default_options)
      self.save
      return self.public_send(options_source)
    end
    return result
  end
  
  def option(key)
    if default_options.key?(key)
      if (opts = options) && opts.key?(key)
        return opts[key]
      end
      return default_options[key]
    end
  end
  
  def set_option(key, val)
    key = key.to_sym
    if default_options.key?(key)
      if options[key] == true || options[key] == false && !(val == true || val == false)
        val = val.downcase
        options[key] = val == 'true' || val == '1'
      else
        options[key] = val
      end
      self.public_send((options_source.to_s + '=').to_sym, options)
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
end

module ActiveRecord
  class Base
    def self.prefs(as, hash = {})
      include Prefable
      @@default_options = hash
      @@options_source = as
      serialize @@options_source.to_sym, Hash
      
      define_method :default_options do
        return @@default_options
      end
      define_method :options_source do
        return @@options_source
      end
    end
  end
end
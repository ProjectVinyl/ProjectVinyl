module Prefable
  def prefs_cache
    @prefs_cache || (@prefs_cache = Preferences.new(self))
  end
  
  def options
    result = self.public_send(options_source)
    if !result || result.empty?
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
    if dirty
      self.update_prefs_column(result).save
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
    puts 'Called @owner.set_option with ' + { :ket => key, :value => val }.to_s
    key = key.to_sym
    if default_options.key?(key)
      ops = options
      if default_options[key] == true || default_options[key] == false
        if !(val == true || val == false)
          val = val.downcase
          val = val == 'true' || val == '1'
        end
        puts 'Assign ' + key.to_s + ' = ' + val.to_s
        ops[key] = val
        puts 'Assigned ops[' + key.to_s + '] => ' + ops[key].to_s
      else
        puts 'Assign ' + key.to_s + ' = "' + val.to_s + '"'
        ops[key] = val
      end
      puts 'Assigned ops[' + key.to_s + '] => ' + ops[key].to_s
      puts 'public_send ' + ops.to_s
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
      puts 'Called Preferences.save with ' + hash.to_s
      hash.keys.each do |key|
        @owner.set_option(key, hash[key])
      end
      @owner.save
    end
  end
  
  def update_prefs_column(hash)
    self.public_send((options_source.to_s + '=').to_sym, hash)
    return self
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
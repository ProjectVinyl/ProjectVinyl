require 'yaml'

module ApplicationSettings
  PATH = Rails.root.join('config', 'settings.yml')

  def self.load
    return YAML::load_file(PATH) || {} if File.exist?(PATH)
    {}
  end

  def self.get(key)
    ApplicationSettings.load[key]
  end

  def self.set(key, value)
    d = ApplicationSettings.load
    d[key] = value
    File.write(PATH, d.to_yaml)
    value
  end

  def self.toggle(key)
    d = ApplicationSettings.load
    d[key] = !d[key]
    File.write(PATH, d.to_yaml)
    d[key]
  end
end

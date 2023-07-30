rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env = ENV['RAILS_ENV'] || 'development'

$es_config = YAML.load_file(rails_root + '/config/elasticsearch.yml')
uri = URI.parse($es_config[rails_env])

Elasticsearch::Model.client = Elasticsearch::Client.new(host: uri.host, port: uri.port)

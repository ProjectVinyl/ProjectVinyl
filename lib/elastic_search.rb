require 'open3'

module ElasticSearch
  READ_ONLY_STRING = ':{\"read_only_allow_delete\":\"true\"}'.freeze
  READ_READ_ONLY_COMMAND = [
    'curl', '-XGET', '-H', 'Content-Type: application/json', 'http://localhost:9200/_all/_settings'
  ].freeze

  def self.read_only=(readonly)
    rd = readonly == true ? 'true' : 'null'

    Open3.capture3(
      'curl', '-XPUT', '-H', 'Content-Type: application/json', 'http://localhost:9200/_all/_settings', '-d',
      "{\"index.blocks.read_only_allow_delete\": #{rd}}"
    )
  end

  def self.read_only?
    stdout, error_str, status = Open3.capture3(*READ_READ_ONLY_COMMAND)
    
    !stdout.match(READ_ONLY_STRING).nil?
  end
end

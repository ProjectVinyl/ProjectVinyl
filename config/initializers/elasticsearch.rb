Elasticsearch::Model::Adapter::ActiveRecord::Records.class_eval do
  def records_memoized
    @_records ||= records_nonmemoized.to_a
  end
  alias_method :records_nonmemoized, :records
  alias_method :records, :records_memoized
end

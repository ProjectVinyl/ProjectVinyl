
module Upsert
  extend ActiveSupport::Concern

  included do
    def self.upsert(hash, returning: nil, unique_by: nil)
      upsert_all([hash], returning: returning, unique_by: unique_by).first
    end

    def self.upsert_all(attributes, returning: nil, on_duplicate: :update, unique_by: nil)
      return none if attributes.empty?

      conn = ActiveRecord::Base.connection

      columns = attributes.first.keys.map(&conn.method(:quote_column_name)).join(',')
      unique_by = unique_by.map(&conn.method(:quote_column_name)).join(',')
      values = attributes.map{ |row| self.send :sanitize_sql_for_conditions, ['(?)', row.values] }.join(',')

      sql = "INSERT INTO #{quoted_table_name} (#{columns}) VALUES #{values} ON CONFLICT (#{unique_by}) DO UPDATE SET id = excluded.id"
      if returning != false
        returning = Array(conn.schema_cache.primary_keys(table_name)) if returning.nil?
        returning = returning.map(&conn.method(:quote_column_name)).join(',')
        sql += " RETURNING #{returning}"
      end

      message = +"#{self} "
      message << "Bulk " if attributes.length > 1
      message << "Upsert"
      conn.exec_query sql, message
    end
  end
end

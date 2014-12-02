require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable

  def where(params)
    values = params.values
    where_line = params.keys.map { |x| "#{x} = ?"}.join(" AND ")

    results = DBConnection.execute(<<-SQL, *values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    self.parse_all(results)
  end
end

class SQLObject
  extend Searchable
end

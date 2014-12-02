require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    db_results = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      SQL

    db_results[0].map { |x| x.to_sym}
  end

  def self.finalize!
    self.columns.each do |attr|
      define_method(attr) do
        instance_variable_get(:@attributes)[attr]
      end
      define_method(attr.to_s+"=") do |value|
        instance_variable_set(:@attributes, @attributes.merge({attr => value}))
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    db_results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      SQL

    self.parse_all(db_results)
  end

  def self.parse_all(results)
    results.map do |obj_hash|
      self.new(obj_hash)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
      SQL

    self.parse_all(result)[0]
  end

  def initialize(params = {})
    @attributes = {}
    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    col_names = self.class.columns.drop(1).join(",")
    question_marks = ["?"] * attribute_values.size
    question_marks = question_marks.join(",")



    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    @attributes[:id] = DBConnection.last_insert_row_id

  end

  def update
    no_id_attributes = @attributes.reject { |k,v| k == :id}
    set_line = self.class.columns.drop(1).map { |x| "#{x} = ?"}.join(",")
    where_line = "#{self.class.columns[0]} = ?"
    values = no_id_attributes.values
    id = @attributes.fetch(:id)

    DBConnection.execute(<<-SQL, *values,id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        #{where_line}
    SQL

  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end
end

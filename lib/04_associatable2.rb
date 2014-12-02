require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]
    source_options = through_options.model_class.assoc_options[source_name]
    p select_table = source_options.table_name

    define_method(name) do

      results = DBConnection.execute(<<-SQL, self.send(through_options.foreign_key))
        SELECT
          #{source_options.table_name}.*
        FROM
          #{through_options.table_name}
        JOIN
          #{source_options.table_name} ON #{through_options.table_name}.#{source_options.foreign_key} = #{source_options.table_name}.#{source_options.primary_key}
        WHERE
          #{through_options.table_name}.#{through_options.primary_key} = ?
      SQL

      source_options.model_class.parse_all(results).first
    end


    # define_method(name) do
    #   p through_options
    #   final_class = source_options.class_name.constantize
    #   final_class.where({ source_options.primary_key => self.send(through_name).send(source_options.foreign_key)}).first
    # end

  end
end

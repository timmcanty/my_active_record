require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.class_name.downcase + "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      foreign_key:  "#{name.to_s.downcase}_id".to_sym,
      primary_key: :id,
      class_name: "#{name}".capitalize }

    init_values = defaults.merge(options)
    self.foreign_key = init_values[:foreign_key]
    self.primary_key = init_values[:primary_key]
    self.class_name = init_values[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      foreign_key: "#{self_class_name.to_s.downcase}_id".to_sym,
      primary_key: :id,
      class_name: "#{name.to_s.singularize.capitalize}"
    }
    init_values = defaults.merge(options)
    self.foreign_key = init_values[:foreign_key]
    self.primary_key = init_values[:primary_key]
    self.class_name = init_values[:class_name]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})

    options = BelongsToOptions.new(name,  options)
    assoc_options[name] = options


    define_method(name) do
      target_model_class = name.to_s.capitalize.constantize
      key = options.foreign_key
      target_model_class.where( { options.primary_key => self.send(key) }).first
    end



  end

  def has_many(name,   options = {})

    class_name = self
    options = HasManyOptions.new(name, class_name , options)
    define_method(name) do
      target_model_class = name.to_s.singularize.capitalize.constantize
      key = options.foreign_key

      target_model_class.where( {key => self.send(options.primary_key) } )
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
  extend Searchable
end

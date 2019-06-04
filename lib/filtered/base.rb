module Filtered
  class Base

    def self.inherited(base)
      base.class_variable_set(:"@@field_definitions", Hash.new)

      def base.field(field_name, options = {}, &block)
        field_definition = FieldDefinition.new

        field_definition.accept_if = if options[:if]
          options[:if]
        else
          ->(value) { !value.nil? && value != "" }
        end

        field_definition.query_update_proc = if block_given?
          # TODO look for methods to validate block to return proc
          block
        else
          # AR
          ->(value) { -> { where(field_name => value) } }
        end

        field_definitions[field_name] = field_definition


        define_method field_name do
          fields[field_name]
        end
      end

      def base.field_definitions
        class_variable_get(:"@@field_definitions")
      end

    end

    def initialize(params, &block)
      @field_set = FieldSet.new(self.class.field_definitions)

      params.each do |name, value|
        name = name.to_sym

        raise Error, "Passing '#{name}' filter which is not defined" unless fields.defined?(name)

        fields[name] = value
      end

      yield self if block_given?
    end

    def fields
      @field_set
    end

    def to_proc
      merge_procs = []

      fields.each do |name, value, definition|

        if definition.accepts_value?(value)
          lambda = definition.to_proc

          value = if lambda.arity == 2
            lambda.call(value, self)
          else
            lambda.call(value)
          end

          merge_procs << value
        end
      end

      ->() {
        # AR
        # self is ActiveRecord relation
        merge_procs.inject(self) { |chain, merge_proc| chain.merge(merge_proc) }
      }
    end

    def to_hash
      Hash[fields.map{|name, value, definition| definition.accepts_value?(value) ? [name, value] : next }.compact]
    end

  end

  class FieldSet
    include Enumerable

    def initialize(definitions)
      @definitions = definitions
    end

    def defined?(name)
      !!@definitions[name]
    end

    def [](name)
      instance_variable_get("@#{name}")
    end

    def []=(name, value)
      instance_variable_set("@#{name}", value)
    end

    def each
      @definitions.each do |name, definition|
        yield name, instance_variable_get("@#{name}"), definition
      end
    end
  end
end

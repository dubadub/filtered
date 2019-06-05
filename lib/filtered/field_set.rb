module Filtered
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

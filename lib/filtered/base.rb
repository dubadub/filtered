module Filtered
  class Base

    def self.inherited(base)
      base.extend ClassMethods
      base.prepend InstanceMehods
    end

    module ClassMethods
      def self.extended(base)
        base.class_variable_set(:"@@field_definitions", Hash.new)
      end

      # Defines a field in a filter.
      #
      # When you provide no options, it will by default add a simple `where(year: ["2010", "2011"])`
      # clause to the query.
      #
      #   class CarFilter < ApplicationFilter
      #
      #     field :year
      #
      #   end
      #
      # Or with a block which is passed with the current field value. Note that block must return
      # proc which will be merged in the query:
      #
      #   class CarFilter < ApplicationFilter
      #
      #     field :year do |value|
      #       -> { where(year: "20#{value}") }
      #     end
      #
      #   end
      #
      # The second argument to a block is filter object itself:
      #
      #   class CarFilter < ApplicationFilter
      #
      #     attr_accessor :user
      #
      #     field :year, allow_blank: true do |value, filter|
      #       -> { where(year: value, user: filter.user) }
      #     end
      #
      #   end
      #
      # Options:
      # * <tt>:default</tt> - Specifies a method (e.g. <tt>default: :default_year</tt>),
      #   proc (e.g. <tt>default:  Proc.new { |filter| filter.default_year }</tt>)
      #   or object (e.g <tt>default: "2012"</tt>) to call to determine default value.
      #   It will be called only if the field not passed into filter constructor.
      # * <tt>:allow_nil</tt> - Add the field into query if field value is +nil+.
      # * <tt>:allow_blank</tt> - Add the field into query if the value is blank.
      # * <tt>:if</tt> - Specifies a method, proc or string to call to determine
      #   if the field addition to query should occur (e.g. <tt>if: :allow_year</tt>,
      #   or <tt>if: Proc.new { |year| %w(2018 2019).include?(year) }</tt>). The method,
      #   proc or string should return or evaluate to a +true+ or +false+ value.
      # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine
      #   if the field addition to query should not occur (e.g. <tt>if: :allow_year</tt>,
      #   or <tt>if: Proc.new { |year| (1999..2005).include?(year) }</tt>). The method,
      #   proc or string should return or evaluate to a +true+ or +false+ value.

      def field(field_name, options = {}, &block)
        field_name = field_name.to_sym
        field_definition = FieldDefinition.new

        field_definition.query_updater = if block_given?
          # TODO look for methods to validate that block returns proc
          block
        else
          # AR ref
          ->(value) { -> { where(field_name => value) } }
        end

        raise Error, "'if' can't be used with 'allow_nil' or 'allow_blank'" if options[:if] && (options[:allow_nil] || options[:allow_blank])

        field_definition.acceptance_computer = if options[:if]
          options[:if]
        else
          ->(value) { (options[:allow_nil] || !value.nil?) && (options[:allow_blank] || value != "") }
        end

        field_definition.default_computer = if options[:default].is_a?(Proc)
          options[:default]
        elsif options[:default].is_a?(Symbol)
          -> (filter) { filter.send(options[:default]) }
        elsif options[:default]
          -> (_) { options[:default] }
        end

        field_definitions[field_name] = field_definition

        define_method field_name do
          fields[field_name]
        end
      end

      def field_definitions
        class_variable_get(:"@@field_definitions")
      end
    end

    module InstanceMehods
      def initialize(*_)
        @field_set = FieldSet.new(self.class.field_definitions)

        super
      end

      private

      def fields
        @field_set
      end
    end

    # Initializes a new filter with the given +params+.
    #
    #
    #   class CarFilter < ApplicationFilter
    #
    #     attr_accessor :user
    #
    #     field :year, allow_blank: true do |value, filter|
    #       -> { where(year: value, user: filter.user) }
    #     end
    #
    #     field :make
    #     field :model
    #     field :body
    #
    #   end
    #
    #   class NoiseMeasurementsController < ApplicationController
    #     before_action :set_filter
    #
    #     def index
    #       @measurements = CarNoiseMeasurement.all.merge(@filter)
    #     end
    #
    #     private
    #
    #     def set_filter
    #       @filter = CarsFilter.new(filter_params) do |f|
    #        f.user = current_user
    #       end
    #     end
    #
    #     def filter_params
    #       params.fetch(:filter, {}).permit(make: [], model: [], year: [], body: [])
    #     end
    #  end
    def initialize(params = {}, &block)
      params.each do |name, value|
        name = name.to_sym

        raise Error, "Passing '#{name}' filter which is not defined" unless fields.defined?(name)

        fields[name] = value
      end

      yield self if block_given?
    end


    # ActiveRecord calls to_proc when filter merged into relation.
    def to_proc
      procs = entitled_fields.inject([]) do |memo, (name, value, definition)|

        r = if (l = definition.query_updater) == 2
          l.call(value, self)
        else
          l.call(value)
        end

        memo << r

        memo
      end

      ->() {
        # here self is an ActiveRecord relation
        procs.inject(self) { |chain, next_proc| chain.merge(next_proc) }
      }
    end

    def to_hash
      Hash[entitled_fields.map { |name, value| [name, value] }]
    end

    def inspect
      inspection = fields.collect { |name, value| "#{name}: #{value.inspect}" }.compact.join(", ")

      "#<#{self.class} #{inspection}>"
    end

    private

    def entitled_fields
      return enum_for(:entitled_fields) unless block_given?

      fields.each do |name, value, definition|
        value = definition.default_computer.(self) if !value && definition.default_computer

        if definition.accepts_value?(value)
          yield name, value, definition
        else
          next
        end
      end
    end

  end
end

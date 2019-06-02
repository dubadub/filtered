class CarFilter < ApplicationFilter
  attr_accessor :user

  # Usage with default values.

  # It will add a simple `.where(year: ["2010", "2011"])` clause to query.
  field :year


  # Or you can fuylly control how Filtered modifies query with a block.
  # Notice that block returns lambda. That's because we want to postpone
  # it's evaluation and let ActiveRecord do that when required.

  # It will add `.joins(:specification).merge(Car::Specification.where(year: ["2010", "2011"]))` clause to query.
  field :year do |year|
    -> { joins(:specification).merge(Car::Specification.where(year: year)) }
  end

  # There are some options to a filter field.

  # `allow_nil` (default is false) will allow nil values to be passed into query.
  # Defatul behaviour is to ignore field althogher if value is nil.
  field :year, allow_nil: true

  # `allow_blank` (default is false) will allow empty values to be passed into query.
  # Defatul behaviour is to ignore field althogher if value is blank.
  field :year, allow_blank: true

  # `default` will set field default value if field is not passed into constructor.
  # it accepts literal value:
  field :year, default: "2019"
  # method name
  field :year, default: :default_year
  # or lambda with filter object as argument
  field :year, default: -> (filter) { filter.default_year }

  # `if` and `unless` will switch filter on or off based on value or filter.
  # it can accept lambda with value as argument:
  field :year, if: -> (value) { %w(2018 2019).include?(value) }
  # or value and filter as argument:
  field :year, if: -> (value, filter) { filter.user.present? && %w(2018 2019).include?(value) }
  # or method name. it will pass value as an argument
  field :year, if: :year_applicable?

  # here is more sofisticated example when we need to do arbitrary logic inside:
  field :ordering do |value|
    order_by, direction = value.split
    # order_by, direction = value.values_at("order", "direction")
    case order_by
    when "year"
      -> { joins(:specification).merge(Car::Specification.order(year: direction)) }
    when "noise_idle"
      -> { order("profile -> '0' #{direction}") }
    when "noise_50"
      -> { order("profile -> '50' #{direction}") }
    when "noise_80"
      -> { order("profile -> '80' #{direction}") }
    else
      raise "Incorrect Filter Value"
    end
  end

  private

  def default_year
    if user
      user.defaults.year
    else
      "2019"
    end
  end

  def year_applicable?(value)
    user.present? && %w(2018 2019).include?(value)
  end

end

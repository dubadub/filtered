class MyFilter < ApplicationFilter
  attr_accessor :employee

  field :ordering do |value|
    order_by, direction = value.split
    # order_by, direction = value.values_at(:order, :direction)

    case order_by
    when "year"
      -> { joins(:specification).merge(Car::Specification.order(year: direction)) }
    when "noise_idle"
      -> { order("profile -> '0' #{direction}") }
    when "noise_50"
      -> { order("profile -> '50' #{direction}") }
    when "noise_80"
      -> { order("profile -> '80' #{direction}") }
    when "noise_100"
      -> { order("profile -> '100' #{direction}") }
    when "noise_120"
      -> { order("profile -> '120' #{direction}") }
    when "noise_140"
      -> { order("profile -> '140' #{direction}") }
    else
      raise "Incorrect Filter Value"
    end
  end

  # Arel

  field :year, allow_blank: true do |year|
    -> { joins(:specification).merge(Car::Specification.where(year: year)) }
  end

  field :year, if: -> (value) { %(abc cda).include?(value) }  do |year|
    -> { joins(:specification).merge(Car::Specification.where(year: year)) }
  end

  field :year, if: -> (value, filter) { filter.employee.id.present? && %(abc cda).include?(value) }  do |year|
    -> { joins(:specification).merge(Car::Specification.where(year: year)) }
  end

  field :year, if: :year_applicable?  do |year|
    -> { joins(:specification).merge(Car::Specification.where(year: year)) }
  end

  field :status
  #
  # => where(status: "value")


  private

  def year_applicable?(value)
    employee.id.present? && %(abc cda).include?(value)
  end

end

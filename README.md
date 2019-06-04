[![Build Status](https://travis-ci.org/dubadub/filtered.svg?branch=master)](https://travis-ci.org/dubadub/filtered)
[![Maintainability](https://api.codeclimate.com/v1/badges/58e6805e1616fd68be56/maintainability)](https://codeclimate.com/github/dubadub/filtered/maintainability)

WORK IN PROGRESS


# Filtered - easily add filter to ActiveRecord queries

Have you ever been overwhelmed by the need to filter ActiveRecord relation in a way which doesn't align with ActiveRecord notation? In particular, use fields which aren't columns or scopes. Do you remember that feeling when you need to display filter values in a form on a page and then parse all these parameters back? Me too. That's it.

Filtered gem is created to solve these problems. Forever.

It gives freedom of using any names, any columns or associations behind these names. Also, it allows you to reuse queries or even compose them from reusable parts.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'filtered'
```

And then execute:

```bash
    # Download and install gem
    $ bundle
    # Generate base filter class
    $ rails generate filtered:install
      create app/filters
      create app/filters/application_filter.rb
```

## Usage

Create a new filter by running:

```bash
    $ rails generate filtered:filter car make model year body # fields are optional
        create app/filiters/user_filter.rb
```



This is how you can use that filter in a controller:

```ruby
# app/controllers/noise_measurements_controller.rb
class NoiseMeasurementsController < ApplicationController

  before_action :set_filter

  def index
    # add `@filter` object as an argument to `merge`
    @measurements = CarNoiseMeasurement.all.merge(@filter).page(params[:page])
  end

  private

  def set_filter
    @filter = CarFilter.new(filter_params)
    # it can take a block as well if you need for example to set value of auxilary variable:
    #
    #   @filter = CarsFilter.new(filter_params) do |f|
    #			f.user = current_user
    #   end
    #
  end

  def filter_params
    params.fetch(:filter, {}).permit(make: [], model: [], year: [], body: [], :ordering)
  end

end
```



Define your filter:

```ruby
# app/filters/car_filter.rb
class CarFilter < ApplicationFilter
  attr_accessor :user

  # Usage with default values.

  # It will add a simple `.where(year: ["2010", "2011"])` clause to query.
  field :year


  # Or you can fully control how Filtered modifies query with a block.
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

```

For full reference see [documentation](https://github.com/dubadub/filtered/blob/master/docs) and [examples](https://github.com/dubadub/filtered/blob/master/examples).

Use the same `@filter` object in views, it will set all inputs values in a form:

```
# app/views/noise_measurements/index.slim

  = form_for(@filter, url: search_path, method: "GET", as: :filter) do |f|
    .fields
      span Year
      - YEARS.each do |year|
        = year
        = f.check_box :year, { multiple: true }, year, nil

    .fields
      span Body
      - BODIES.each do |body|
				= body
        = f.check_box :body, { multiple: true }, body, nil

    .fields
      span Make
      - MAKES.each do |make|
        = make
        = f.check_box :make, { multiple: true }, make, nil

    .fields
      span Sorting

	  span Year
      = f.radio_button :ordering, "year asc"
      = f.radio_button :ordering, "year desc"

	  span Idle
      = f.radio_button :ordering, "noise_idle asc"
      = f.radio_button :ordering, "noise_idle desc"
      span 50
      = f.radio_button :ordering, "noise_50 asc"
      = f.radio_button :ordering, "noise_50 desc"
      span 80
      = f.radio_button :ordering, "noise_80 asc"
      = f.radio_button :ordering, "noise_80 desc"

    .actions
      = f.submit "Filter"
```

## Under the hood

Filtered uses API provided by ActiveRecord [merge method](https://api.rubyonrails.org/classes/ActiveRecord/SpawnMethods.html#method-i-merge). There are a few open issues in ActiveRecord related to that method, please, have a look through it [here](https://github.com/rails/rails/search?q=activerecord+merge&state=open&type=Issues).

## Credits

This gem woudn't exist without original ideas of [@caJaeger](https://github.com/caJaeger).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dubadub/filtered. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Filtered project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dubadub/filtered/blob/master/CODE_OF_CONDUCT.md).

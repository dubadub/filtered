[![Build Status](https://travis-ci.org/dubadub/filtered.svg?branch=master)](https://travis-ci.org/dubadub/filtered)


# Filtered - add filter to ActiveRecord queries

It gives freedom of using any names, columns, scopes or associations behind these names. Also, it allows you to reuse queries or even compose them from reusable parts. Nice part about it is that it ingerates with Rails forms out of the box.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "filtered"
```

And then run:

```bash
    # 1. Download and install the gem
    $ bundle

    # 2. Generate a base filter class
    $ rails generate filtered:install
          create app/filters/application_filter.rb
```

## Usage

To create a new filter with a generator:

```bash
    $ rails generate filter car make model year body # fields can be added later
          create app/filiters/car_filter.rb
```


To use this filter in a controller:

```ruby
# app/controllers/noise_measurements_controller.rb
class NoiseMeasurementsController < ApplicationController

  before_action :set_filter

  def index
    @measurements = CarNoiseMeasurement.all.merge(@filter)
  end

  private

  def set_filter
    # it can take an optional block if you need to set an auxilary variable:
    @filter = CarsFilter.new(filter_params) do |f|
      f.user = current_user
    end
  end

  def filter_params
    params.fetch(:filter, {}).permit(make: [], model: [], year: [], body: [], :ordering)
  end

end
```


To define your filter:

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

  # It will add `.joins(:specification).merge(Car::Specification.where(year: ["2010", "2011"]))`
  # clause to the query.
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

To use the same `@filter` object in views (it will automatically set all the related inputs in a form):

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

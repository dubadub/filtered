require "spec_helper"
require "generator_spec"
require "generators/filter/filter_generator"

RSpec.describe FilterGenerator, type: :generator do
  destination File.expand_path("../../tmp", __FILE__)
  arguments %w(users group persmission)

  before(:all) do
    prepare_destination
    run_generator
  end

  it "creates a filter file" do
    assert_file "app/filters/users_filter.rb", /class UsersFilter < ApplicationFilter/
  end
end

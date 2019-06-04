require "spec_helper"
require "generator_spec"
require "generators/filtered/install/install_generator"

RSpec.describe Filtered::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../tmp", __FILE__)

  before(:all) do
    prepare_destination
    run_generator
  end

  it "creates a base file" do
    assert_file "app/filters/application_filter.rb"
  end
end

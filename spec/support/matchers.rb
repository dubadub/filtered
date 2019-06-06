RSpec::Matchers.define :have_filter_value do |expected|
  match do |actual|
    actual.to_hash == expected
  end

end

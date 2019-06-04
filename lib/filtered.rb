module Filtered

  require "filtered/version"
  require "filtered/field_definition"
  require "filtered/base"

  if defined?(Rails)
    require "filtered/engine"
  end

  class Error < StandardError; end
end

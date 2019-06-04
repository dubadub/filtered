module Filtered
  class Engine < ::Rails::Engine
    config.autoload_paths += Dir["#{config.root}/app/filters/**/"]
  end
end

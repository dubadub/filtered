module Filtered
  module Generators
    class InstallGenerator < Rails::Generators::Base

      source_root File.expand_path("templates", __dir__)

      def generate_install
        copy_file "application_filter.rb", "app/filters/application_filter.rb"
      end
    end
  end
end

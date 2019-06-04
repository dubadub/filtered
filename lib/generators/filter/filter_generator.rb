class FilterGenerator < Rails::Generators::NamedBase
  check_class_collision suffix: "Filter"

  source_root File.expand_path("templates", __dir__)

  argument :fields, type: :array, default: [], banner: "field field"

  def create_filter_file
    template "filter.rb", File.join("app/filters", class_path, "#{file_name}_filter.rb")
  end

  private

  def file_name
    @_file_name ||= super.sub(/_filter\z/i, "")
  end
end

module SQLHelpers

  def connect_db
    # ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger = nil

    if ENV["DB"] == "sqlite"
      connect_sqlite
    elsif ENV["DB"] == "postgres"
      connect_postgres
    else
      raise StandardError, "database not supported, provide it in ENV['DB']. Supported versions are: 'sqlite' and 'postgres'."
    end
  end

  def define_db_schema(&block)
    connect_db
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Schema.define(&block)
  end

  private

  def connect_sqlite
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
  end

  def connect_postgres
    ActiveRecord::Base.establish_connection(adapter: "postgresql", host: "localhost",
                                            database: "postgres", schema_search_path: "public")

    ActiveRecord::Base.connection.drop_database("action_filter_postgresql_spec")
    ActiveRecord::Base.connection.create_database("action_filter_postgresql_spec",
                                                   encoding: "utf-8", adapter: "postgresql")

    ActiveRecord::Base.establish_connection(adapter: "postgresql", host: "localhost",
                                            database: "action_filter_postgresql_spec")
  end
end

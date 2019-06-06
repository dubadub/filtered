RSpec.describe "Integration with ActiveRecord" do
  before :each do
    define_db_schema do
      create_table(:parents) do |t|
        t.string :status
        t.timestamps null: false
      end

      create_table(:children) do |t|
        t.integer :parent_id
        t.timestamps null: false
      end
    end

    class Parent < ActiveRecord::Base
      has_many :children, -> { order(id: :desc) }
    end

    class Child < ActiveRecord::Base
      belongs_to :parent
    end
  end

  let(:filter_class) do
    Class.new(Filtered::Base) do
      field :status

      field :has_children, if: ->(value) { !!value } do |value|
        -> { joins(:children) }
      end
    end
  end

  it "doesn't modify query if filter has no values" do
    filter = filter_class.new

    expect(Parent.all.merge(filter).to_sql).to eq("SELECT \"parents\".* FROM \"parents\"")
  end

  it "adds where statement to query when field defined with default settings" do
    filter = filter_class.new(status: "pending")

    expect(Parent.all.merge(filter).to_sql).to eq("SELECT \"parents\".* FROM \"parents\" WHERE \"parents\".\"status\" = 'pending'")
  end

  it "adds condition for children if value is truthy" do
    filter = filter_class.new(status: "pending", has_children: true)

    expect(Parent.all.merge(filter).to_sql).to eq("SELECT \"parents\".* FROM \"parents\" INNER JOIN \"children\" ON \"children\".\"parent_id\" = \"parents\".\"id\" WHERE \"parents\".\"status\" = 'pending'")
  end

  it "doesn't adds condition for children if value is falsey" do
    filter = filter_class.new(has_children: false)

    expect(Parent.all.merge(filter).to_sql).to eq("SELECT \"parents\".* FROM \"parents\"")
  end
end

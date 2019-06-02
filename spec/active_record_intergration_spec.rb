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

  it "filters parents" do
    class MyFilter < ActionFilter::Base
      field :status
    end

    filter = MyFilter.new(status: "pending")

    expect(Parent.all.merge(filter).to_sql).to eq("SELECT \"parents\".* FROM \"parents\" WHERE \"parents\".\"status\" = 'pending'")
  end
end

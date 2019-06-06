RSpec.describe Filtered do
  it "has a version number" do
    expect(Filtered::VERSION).not_to be nil
  end

  describe "DSL" do
    it "doesn't clash with other class" do
      class FilterOne < Filtered::Base
        field :status
      end

      class FilterTwo < Filtered::Base
        field :reason
      end

      filter_one = FilterOne.new(status: "pending")
      filter_two = FilterTwo.new(reason: "pending")

      expect(filter_one.to_hash).to eq(status: "pending")
      expect(filter_two.to_hash).to eq(reason: "pending")
    end

    it "blows up when setting field which is not defined" do
      class MyFilter < Filtered::Base
        field :status
      end

      expect { MyFilter.new(reason: "haha") }.to raise_error(/Passing 'reason' filter which is not defined/)
    end

    describe "field" do
      context "without parameters" do
        it "works with value present" do
          class MyFilter < Filtered::Base
            field :status
          end

          filter = MyFilter.new(status: "pending")

          expect(filter).to have_filter_value(status: "pending")
        end

        it "works when no value present" do
          class MyFilter < Filtered::Base
            field :status
          end

          filter = MyFilter.new(status: "")

          expect(filter).to have_filter_value({})
        end
      end

      context "with block parameter" do
        it "works" do
          class MyFilter < Filtered::Base
            field :status do |value|
              -> { where(status: value) }
            end
          end

          filter = MyFilter.new(status: "pending")

          expect(filter).to have_filter_value(status: "pending")
        end

        it "gives access to filter instance" do
          class MyFilter < Filtered::Base
            field :status do |value, filter|
              -> { where(status: filter.prefixed(value)) }
            end

            def prefixed(value)
              "m_#{value}"
            end
          end

          filter = MyFilter.new(status: "pending")

          expect(filter).to have_filter_value(status: "pending")
        end

        xit "raises an error if field definition doesn't return lambda" do
          expect {
            class MyFilter < Filtered::Base
              field :status do |value|
                "hello"
              end

            end
          }.to raise_error(/Field must return lambda/)
        end
      end

      context "field options" do
        describe "if: ..." do
          it "supports 'if: :method_name'" do
            class MyIfFilter < Filtered::Base
              field :status, if: :use_field?

              def use_field?(value)
                value == "pending"
              end
            end

            filter = MyIfFilter.new(status: "pending")

            expect(filter).to have_filter_value(status: "pending")
          end

          it "supports 'if: :method_name'" do
            class MyIfFilter < Filtered::Base
              field :status, if: :use_field?

              def use_field?(value)
                value != "pending"
              end
            end

            filter = MyIfFilter.new(status: "pending")

            expect(filter).to have_filter_value({})
          end

          xit "supports 'unless: :method_name'" do
            class MyFilter < Filtered::Base
              field :status, unless: :skip_field?

              def skip_field?
                true
              end
            end

            filter = MyFilter.new(status: "pending")

            expect(filter).to have_filter_value({})
          end

          it "supports 'if: ->() {...}'" do
            class MyFilter < Filtered::Base
              field :status, if: ->() { false }
            end

            filter = MyFilter.new(status: "pending")

            expect(filter).to have_filter_value({})
          end

          it "supports 'if: ->() {...}'" do
            class MyFilter < Filtered::Base
              field :status, if: ->() { true }
            end

            filter = MyFilter.new(status: "pending")

            expect(filter).to have_filter_value(status: "pending")
          end

          it "supports 'if: ->(value) {...}'" do
            class MyFilter < Filtered::Base
              field :status, if: ->(value) { !value }
            end

            filter = MyFilter.new(status: "pending")

            expect(filter).to have_filter_value({})
          end

          it "supports 'if: ->(value) {...}'" do
            class MyFilter < Filtered::Base
              field :status, if: ->(value) { value }
            end

            filter = MyFilter.new(status: "pending")

            expect(filter).to have_filter_value(status: "pending")
          end
        end


        describe "allow_blank: ..." do
          context "when 'allow_blank: true'" do
            it "allows blank values in query" do
              class MyFilter < Filtered::Base
                field :status, allow_blank: true
              end

              filter = MyFilter.new(status: "")

              expect(filter).to have_filter_value(status: "")
            end
          end
        end

        describe "allow_nil: ..." do
          context "when 'allow_nil: true'" do
            it "allows nil values in query" do
              class MyFilter < Filtered::Base
                field :status, allow_nil: true
              end

              filter = MyFilter.new(status: nil)

              expect(filter).to have_filter_value(status: nil)
            end
          end
        end

        describe "default: ..." do
          it "supports 'default' as value" do
            class MyNewFilter < Filtered::Base
              field :year, default: 2019
            end

            filter = MyNewFilter.new

            expect(filter).to have_filter_value(year: 2019)
          end

          it "supports  'default' as proc" do
            class MyNewFilter < Filtered::Base
              attr_accessor :default_year

              field :year, default: ->(filter) { filter.default_year }
            end

            filter = MyNewFilter.new do |f|
              f.default_year = 2019
            end

            expect(filter).to have_filter_value(year: 2019)
          end

          it "supports  'default' as method name" do
            class MyNewFilter < Filtered::Base
              field :year, default: :default_year

              def default_year
                2019
              end
            end

            filter = MyNewFilter.new

            expect(filter).to have_filter_value(year: 2019)
          end
        end

      end
    end
  end
end

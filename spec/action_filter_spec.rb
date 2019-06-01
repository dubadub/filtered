RSpec.describe ActionFilter do
  it "has a version number" do
    expect(ActionFilter::VERSION).not_to be nil
  end

  describe "DSL" do
    describe "field" do
      context "without parameters" do
        it "works with value present" do
          class MyFilter < ActionFilter::Base
            field :status
          end

          filter = MyFilter.new(status: "pending")

          expect(filter.to_hash).to eq(status: "pending")
        end

        it "works when no value present" do
          class MyFilter < ActionFilter::Base
            field :status
          end

          filter = MyFilter.new(status: "")

          expect(filter.to_hash).to eq({})
        end
      end

      context "with block parameter" do
        it "works" do
          class MyFilter < ActionFilter::Base
            field :status do |value|
              -> { where(status: value) }
            end
          end

          filter = MyFilter.new(status: "pending")

          expect(filter.to_hash).to eq(status: "pending")
        end

        it "gives access to filter instance" do
          class MyFilter < ActionFilter::Base
            field :status do |value, filter|
              -> { where(status: filter.prefixed(value)) }
            end

            def prefixed(value)
              "m_#{value}"
            end
          end

          filter = MyFilter.new(status: "pending")

          expect(filter.to_hash).to eq(status: "pending")
        end

        it "raises an error if field definition doesn't return lambda" do
          expect {
            class MyFilter < ActionFilter::Base
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
            class MyFilter < ActionFilter::Base
              field :status, if: :use_field?

              def use_field?
                false
              end
            end

            filter = MyFilter.new(status: "pending")

            expect(filter.to_hash).to eq({})
          end

          it "supports 'unless: :method_name'" do
            class MyFilter < ActionFilter::Base
              field :status, unless: :skip_field?

              def skip_field?
                true
              end
            end

            filter = MyFilter.new(status: "pending")

            expect(filter.to_hash).to eq({})
          end

          it "supports 'if: ->() {...}'" do
            class MyFilter < ActionFilter::Base
              field :status, if: -> { false }
            end

            filter = MyFilter.new(status: "pending")

            expect(filter.to_hash).to eq({})
          end

          it "supports 'if: ->() {...}'" do
            class MyFilter < ActionFilter::Base
              field :status, if: -> { false }
            end

            filter = MyFilter.new(status: "pending")

            expect(filter.to_hash).to eq({})
          end
        end


        describe "allow_blank: ..." do
          it "supports 'allow_blank: true'" do
            class MyFilter < ActionFilter::Base
              field :status, allow_blank: true
            end

            filter = MyFilter.new(status: "")

            expect(filter.to_hash).to eq(status: "")
          end
        end

      end



    end
  end
end

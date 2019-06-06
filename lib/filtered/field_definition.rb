module Filtered
  class FieldDefinition

    attr_accessor :query_updater, :acceptance_computer, :default_computer

    def accepts_value?(value)
      @acceptance_computer.call(value)
    end

  end
end

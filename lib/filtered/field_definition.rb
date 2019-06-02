module Filtered
  class FieldDefinition

    attr_writer :query_update_proc, :accept_if

    def accepts_value?(value)
      @accept_if.call(value)
    end

    def to_proc
      @query_update_proc
    end

  end
end

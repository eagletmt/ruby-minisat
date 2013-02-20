module MiniSat
  class Solver
    alias_method :<<, :add_clause

    # Iterates over all models
    # @yield [model]
    # @yieldparam [MiniSat::Model] model the model that satisfies given clauses.
    def each_model(&blk)
      if blk
        while model = solve
          blk.call model
          add_clause model.to_negative
        end
      else
        enumerator_class.new self, :each_model
      end
    end

    private

    def enumerator_class
      @enumerator_class ||= defined?(Enumerator) ? Enumerator : Enumerable::Enumerator
    end
  end
end

module MiniSat
  class Solver
    alias_method :<<, :add_clause

    # Iterates over all models
    # @yield [model]
    # @yieldparam [MiniSat::Model] model the model that satisfies given clauses.
    def each_model(&blk)
      e = Enumerator.new do |y|
        while model = solve
          y << model
          add_clause model.to_negative
        end
      end
      if blk
        e.each &blk
      else
        e
      end
    end
  end
end

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
        to_enum(:each_model)
      end
    end
  end
end

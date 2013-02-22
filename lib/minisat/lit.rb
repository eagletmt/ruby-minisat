module MiniSat
  class Lit
    include Formula

    # Convert to a CNF formula
    #
    # @return [Array<Array<Lit>>]
    def to_cnf
      [[self]]
    end

    # Returns its index (1-origin for DIMACS format).
    # Returns negative index if this literal is negative.
    def to_i
      n = to_var.to_i
      positive? ? n : -n
    end

    # Do Tseitin transformation
    # @param [Solver] solver SAT solver for generating new variables
    # @return [TseitinPair]
    def tseitin(solver)
      TseitinPair.new self, []
    end
  end
end

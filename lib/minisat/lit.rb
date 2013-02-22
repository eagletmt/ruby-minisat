module MiniSat
  class Lit
    include Formula

    # Convert to a CNF formula
    #
    # @return [Array<Array<Lit>>]
    def to_cnf
      [[self]]
    end

    # Do Tseitin transformation
    # @param [Solver] solver SAT solver for generating new variables
    # @return [TseitinPair]
    def tseitin(solver)
      TseitinPair.new self, []
    end
  end
end

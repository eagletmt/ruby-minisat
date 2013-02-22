module MiniSat
  class Lit
    include Formula

    # Convert to a CNF formula
    #
    # @return [Array<Array<Lit>>]
    def to_cnf
      [[self]]
    end
  end
end

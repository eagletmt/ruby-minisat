module MiniSat
  class Var
    include Formula

    # Convert to a negative literal.
    # Shortcut for +-to_lit+
    #
    # @return [MiniSat::Lit]
    def -@
      -to_lit
    end

    # Convert to a CNF formula
    #
    # @return [Array<Array<Lit>>]
    def to_cnf
      [[self.to_lit]]
    end
  end
end

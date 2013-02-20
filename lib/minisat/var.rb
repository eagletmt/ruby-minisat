module MiniSat
  class Var
    # Convert to a negative literal.
    # Shortcut for +-to_lit+
    #
    # @return [MiniSat::Lit]
    def -@
      -to_lit
    end
  end
end

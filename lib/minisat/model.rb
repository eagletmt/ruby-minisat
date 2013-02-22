module MiniSat
  class Model
    # Returns an array containing the assignment corresponding to the given +vars+.
    # @param [Array<Lit, Var>] vars
    # @return [Array<Boolean>]
    def values_at(*vars)
      vars.map do |v|
        self[v]
      end
    end
  end
end

module MiniSat
  module Formula
    # self /\ r
    # @return [Formula]
    def land(r)
      And.new self, r
    end
    alias_method :&, :land

    # self \\/ r
    # @return [Formula]
    def lor(r)
      Or.new self, r
    end
    alias_method :|, :lor

    # self => r
    # @return [Formula]
    def imp(r)
      Or.new -self, r
    end
  end

  class And
    include Formula

    # @!attribute [rw] lhs
    #  @return [Formula] left hand side of And
    # @!attribute [rw] rhs
    #  @return [Formula] right hand side of And
    attr_accessor :lhs, :rhs
    def initialize(l, r)
      @lhs = l
      @rhs = r
    end

    # Negates _and_ formula
    # @return [Formula]
    def -@
      Or.new -lhs, -rhs
    end

    # Convert to a CNF formula
    # @return [Array<Array<Lit>>]
    def to_cnf
      lhs.to_cnf + rhs.to_cnf
    end
  end

  class Or
    include Formula

    # @!attribute [rw] lhs
    #  @return [Formula] left hand side of Or
    # @!attribute [rw] rhs
    #  @return [Formula] right hand side of Or
    attr_accessor :lhs, :rhs
    def initialize(l, r)
      @lhs = l
      @rhs = r
    end

    # Negates _or_ formula
    # @return [Formula]
    def -@
      And.new -lhs, -rhs
    end

    # Convert to a CNF formula
    # @return [Array<Array<Lit>>]
    def to_cnf
      ls = lhs.to_cnf
      rs = rhs.to_cnf
      ls.flat_map do |l|
        rs.map do |r|
          l + r
        end
      end
    end
  end
end

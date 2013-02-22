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

  class TseitinPair
    # @return [Var] variable introduced by Tseitin transformation
    attr_reader :var
    # @return [Array<Array<Lit>>] CNF formula encoded by Tseitin transformation
    attr_reader :cnf
    def initialize(var, cnf)
      @var = var
      @cnf = cnf
    end

    # @return [Array<Array<Lit>>]
    def to_cnf
      [[var]] + cnf
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

    # Do Tseitin transformation
    # @param [Solver] solver SAT solvervar
    # @return [TseitinPair]
    def tseitin(solver)
      v = Var.new solver
      l = lhs.tseitin solver
      r = rhs.tseitin solver
      TseitinPair.new(v, [[-v, l.var], [-v, r.var], [v, -l.var, -r.var]] + l.cnf + r.cnf)
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
      ls.map do |l|
        rs.map do |r|
          l + r
        end
      end.flatten(1)
    end

    # Do Tseitin transformation
    # @param [Solver] solver SAT solvervar
    # @return [Array<Array<Lit>>]
    def tseitin(solver)
      v = Var.new solver
      l = lhs.tseitin solver
      r = rhs.tseitin solver
      TseitinPair.new(v, [[-v, l.var, r.var], [v, -l.var], [v, -r.var]] + l.cnf + r.cnf)
    end
  end
end

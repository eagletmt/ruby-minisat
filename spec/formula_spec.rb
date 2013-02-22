require 'spec_helper'
require 'minisat/formula'

describe MiniSat::Formula do
  before do
    @solver = MiniSat::Solver.new
  end

  describe '#to_cnf' do
    it 'works' do
      x1, x2, x3 = 3.times.map { MiniSat::Var.new @solver }
      formula = x1.imp(x2 & x3)

      cnf = [[-x1, x2.to_lit], [-x1, x3.to_lit]]
      expect(formula.to_cnf).to eq(cnf)
      expect do
        cnf.each do |clause|
          @solver << clause
        end
      end.not_to raise_error(Exception)
    end
  end
end

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

  describe '#tseitin' do
    it 'works' do
      x1, x2, x3 = 3.times.map { MiniSat::Var.new @solver }
      formula = x1.imp(x2 & x3)

      pair = formula.tseitin @solver
      expect(pair).to be_a(MiniSat::TseitinPair)
      expect(pair.cnf).to have(3*(3-1)).items  # 3*(NUMBER_OF_LITERALS - 1)
      cnf = pair.to_cnf
      expect do
        cnf.each do |clause|
          @solver << clause
        end
      end.not_to raise_error(Exception)
      expect(@solver.solve).not_to be_nil
    end
  end
end

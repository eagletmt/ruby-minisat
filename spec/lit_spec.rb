require 'spec_helper'

describe MiniSat::Lit do
  before do
    @solver = MiniSat::Solver.new
  end

  it 'cannot be created by new' do
    expect { MiniSat::Lit.new }.to raise_error(NoMethodError)
  end

  describe '#to_var' do
    it 'returns MiniSat::Var' do
      l = MiniSat::Var.new(@solver).to_lit
      expect(l.to_var).to be_a(MiniSat::Var)
    end

    it 'round-trip' do
      l = MiniSat::Var.new(@solver).to_lit
      expect(l.to_var.to_lit).to eq(l)
    end
  end

  describe '#-@' do
    it 'negates self' do
      v = MiniSat::Var.new @solver
      l = v.to_lit
      expect(l).to be_positive
      expect(-l).to be_negative
      expect(l).to be_positive
    end
  end

  describe '#==' do
    it 'returns false if the sign differs' do
      v = MiniSat::Var.new @solver
      expect(v.to_lit).not_to eq(-v)
    end
  end
end

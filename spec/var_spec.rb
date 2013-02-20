require 'spec_helper'

describe MiniSat::Var do
  before do
    @solver = MiniSat::Solver.new
    @var = MiniSat::Var.new @solver
  end

  describe '#initialize' do
    it 'cannot be created by new without arguments' do
      expect { MiniSat::Var.new }.to raise_error(ArgumentError)
    end

    it 'cannot be  created by new with wrong solver' do
      expect { MiniSat::Var.new [] }.to raise_error(TypeError)
    end
  end

  describe '#to_lit' do
    it 'returns a positive literal' do
      lit = @var.to_lit
      expect(lit).to be_a(MiniSat::Lit)
      expect(lit).to be_positive
    end

    it 'round-trip' do
      expect(@var).to eq(@var.to_lit.to_var)
    end
  end

  describe '#to_i' do
    it 'returns index' do
      v2 = MiniSat::Var.new @solver
      expect(@var.to_i).to eq(0)
      expect(v2.to_i).to eq(1)
    end
  end

  describe '#-@' do
    it 'returns a negative literal' do
      lit = -@var
      expect(lit).to be_a(MiniSat::Lit)
      expect(lit).to be_negative
    end
  end
end

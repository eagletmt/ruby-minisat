require 'spec_helper'

describe MiniSat::Solver do
  before do
    @solver = MiniSat::Solver.new
  end

  describe '#<<' do
    it 'accepts MiniSat::Var and returns self' do
      v = MiniSat::Var.new @solver
      expect(@solver << [v]).to eq(@solver)
    end

    it 'accepts MiniSat::Lit and returns self' do
      v = MiniSat::Var.new @solver
      expect(@solver << [-v]).to eq(@solver)
    end

    it 'rejects non-variable' do
      expect { @solver << [1] }.to raise_error(TypeError)
      expect { @solver << [nil] }.to raise_error(TypeError)
    end

    it 'rejects variables from a different solver' do
      s = MiniSat::Solver.new
      v = MiniSat::Var.new s
      expect { @solver << [v] }.to raise_error(ArgumentError)
    end
  end

  describe '#solve' do
    context 'with SAT' do
      it 'returns true' do
        v1 = MiniSat::Var.new @solver
        v2 = MiniSat::Var.new @solver
        l2 = -v2
        @solver << [v1] << [l2]
        model = @solver.solve
        expect(model).to be_a(MiniSat::Model)
      end
    end

    context 'with UNSAT' do
      it 'returns false' do
        v1 = MiniSat::Var.new @solver
        v2 = MiniSat::Var.new @solver
        @solver << [v1, v2] << [-v1, -v2] << [-v1, v2] << [v1, -v2]
        model = @solver.solve
        expect(model).to be_nil
      end
    end
  end

  describe '#each_model' do
    before do
      @v1 = MiniSat::Var.new @solver
      @v2 = MiniSat::Var.new @solver
      @solver << [@v1, @v2]
    end

    it 'iterates over all models' do
      a = []
      @solver.each_model do |model|
        expect(model).to be_a(MiniSat::Model)
        a << [@v1, @v2].map { |v| model[v] }
      end
      expect(a).to have(3).items
      expect(a).to include([true, true])
      expect(a).to include([true, false])
      expect(a).to include([false, true])
    end

    context 'without block' do
      it 'returns an Enumerator' do
        e = @solver.each_model
        expect(e).to be_a(Enumerable)
        n = 0
        e.each do |model|
          expect(model).to be_a(MiniSat::Model)
          n += 1
        end
        expect(n).to eq(3)
      end
    end
  end
end

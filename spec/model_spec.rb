describe MiniSat::Model do
  it 'cannot be created by new' do
    expect { MiniSat::Model.new }.to raise_error(NoMethodError)
  end

  describe '#[]' do
    before do
      @solver = MiniSat::Solver.new
      @v1 = MiniSat::Var.new @solver
      @v2 = MiniSat::Var.new @solver
      @solver << [@v1] << [-@v2]
      @model = @solver.solve
    end

    it 'accepts MiniSat::Var' do
      expect(@model[@v1]).to be_true
      expect(@model[@v2]).to be_false
    end

    it 'accepts MiniSat::Lit' do
      expect(@model[@v1.to_lit]).to be_true
      expect(@model[-@v1]).to be_false
      expect(@model[@v2.to_lit]).to be_false
      expect(@model[-@v2]).to be_true
    end

    it 'rejects others' do
      expect { @model[0] }.to raise_error(TypeError)
      expect { @model[nil] }.to raise_error(TypeError)
    end

    it 'rejects MiniSat::Var/MiniSat::Lit from a different solver' do
      solver = MiniSat::Solver.new
      v = MiniSat::Var.new solver
      expect { @model[v] }.to raise_error(ArgumentError)
      expect { @model[v.to_lit] }.to raise_error(ArgumentError)
      expect { @model[-v] }.to raise_error(ArgumentError)
    end
  end

  describe '#to_negative' do
    before do
      @solver = MiniSat::Solver.new
      @v1 = MiniSat::Var.new @solver
      @v2 = MiniSat::Var.new @solver
      @solver << [@v1, @v2]
      @model = @solver.solve
    end

    it 'returns negative clause' do
      clause = @model.to_negative
      expect(clause).to be_a(Array)
      expect(clause).to have(2).items
      expect(clause[0].to_var).to eq(@v1)
      expect(clause[1].to_var).to eq(@v2)
    end
  end

  describe '#size' do
    before do
      @solver = MiniSat::Solver.new
      @v1 = MiniSat::Var.new @solver
      @v2 = MiniSat::Var.new @solver
      @solver << [@v2]
      @model = @solver.solve
    end

    it 'returns size' do
      expect(@model.size).to eq(2)
    end
  end
end

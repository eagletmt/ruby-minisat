require 'mkmf'
require 'fileutils'

top = File.expand_path('../../../vendor/minisat', __FILE__)
$objs = %W[minisat.o Solver.o]
$INCFLAGS = "#{$INCFLAGS} -I#{top}"

# XXX: Why mkmf doesn't see $CXXFLAGS ?
unless defined?(MakeMakefile::CONFIG)
  # Ruby 1.9
  module MakeMakefile
    CONFIG = ::CONFIG
  end
end
MakeMakefile::CONFIG['CXXFLAGS'] += ' -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS'

FileUtils.ln_s File.join(top, 'core', 'Solver.cc'), '.', force: true

if have_library 'stdc++'
  create_makefile 'minisat'
end

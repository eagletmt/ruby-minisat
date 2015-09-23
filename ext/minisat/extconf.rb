require 'mkmf'
require 'fileutils'

top = File.expand_path('../../../vendor/minisat', __FILE__)
$srcs = %W[minisat.cc Solver.cc]
$INCFLAGS = "#{$INCFLAGS} -I#{top}"

FileUtils.ln_s(File.join(top, 'core', 'Solver.cc'), '.', force: true)

create_makefile 'minisat'

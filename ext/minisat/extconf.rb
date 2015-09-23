require 'mkmf'
require 'fileutils'

top = File.expand_path('../../../vendor/minisat', __FILE__)
$srcs = %W[minisat.cc Solver.cc]
$INCFLAGS = "#{$INCFLAGS} -I#{top}"
$CPPFLAGS = "#{$CPPFLAGS} -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS"

FileUtils.ln_s(File.join(top, 'core', 'Solver.cc'), '.', force: true)

create_makefile 'minisat'

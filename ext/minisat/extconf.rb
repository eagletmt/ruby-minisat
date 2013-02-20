require 'mkmf'

top = File.expand_path('../../../vendor/minisat', __FILE__)
$objs = %W[minisat.o Solver.o]
$INCFLAGS = "#{$INCFLAGS} -I#{top}"
$CFLAGS = "#{$CFLAGS} -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS"

if have_library 'stdc++'
  create_makefile 'minisat'
end

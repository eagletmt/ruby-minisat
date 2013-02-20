require 'mkmf'

top = File.expand_path('../../../vendor/minisat', __FILE__)
solver = File.join(top, 'core', 'Solver.o')
$objs = %W[minisat.o #{solver}]
$INCFLAGS = "#{$INCFLAGS} -I#{top}"
$CFLAGS = "#{$CFLAGS} -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS"

if have_library 'stdc++'
  create_makefile 'minisat'
end

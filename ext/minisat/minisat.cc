#include <ruby.h>
#include "core/Solver.h"

extern "C" {
VALUE rb_mMiniSat;
VALUE rb_cSolver, rb_cVar, rb_cLit, rb_cModel;

void Init_minisat(void);
}

struct VarWrapper
{
  Minisat::Var var;
  VALUE solver;
};

struct LitWrapper
{
  Minisat::Lit lit;
  VALUE solver;
};

struct Model
{
  Minisat::lbool *ary;
  int size;
  VALUE solver;
};

static VALUE minisat_solver_alloc(VALUE klass);
static void minisat_solver_free(void *solver);
static size_t minisat_solver_memsize(const void *solver);
static VALUE minisat_solver_add_clause(VALUE self, VALUE lits);
static VALUE minisat_solver_solve(VALUE self);

static void minisat_var_mark(void *wrapper);
static void minisat_var_free(void *wrapper);
static size_t minisat_var_memsize(const void *wrapper);
static VALUE minisat_var_alloc(VALUE klass);
static VALUE minisat_var_initialize(VALUE self, VALUE solver);
static VALUE minisat_var_to_lit(VALUE self);
static VALUE minisat_var_to_i(VALUE self);
static VALUE minisat_var_eq(VALUE self, VALUE arg);

static void minisat_lit_mark(void *wrapper);
static void minisat_lit_free(void *wrapper);
static size_t minisat_lit_memsize(const void *wrapper);
static VALUE minisat_lit_positive_p(VALUE self);
static VALUE minisat_lit_to_var(VALUE self);
static VALUE minisat_lit_negative_p(VALUE self);
static VALUE minisat_lit_neg(VALUE self);
static VALUE minisat_lit_eq(VALUE self, VALUE arg);

static void minisat_model_mark(void *model);
static void minisat_model_free(void *model);
static VALUE minisat_model_ref(VALUE self, VALUE var);
static VALUE minisat_model_size(VALUE self);
static VALUE minisat_model_to_negative(VALUE self);

static const rb_data_type_t minisat_solver_type = {
  "minisat_solver",
  { NULL, minisat_solver_free, minisat_solver_memsize, },
  NULL, NULL,
};
static const rb_data_type_t minisat_var_type = {
  "minisat_var",
  { minisat_var_mark, minisat_var_free, minisat_var_memsize, },
  NULL, NULL,
};
static const rb_data_type_t minisat_lit_type = {
  "minisat_lit",
  { minisat_lit_mark, minisat_lit_free, minisat_lit_memsize, },
  NULL, NULL,
};

static inline bool solver_type_p(VALUE v) { return TYPE(v) == T_DATA && RTYPEDDATA_TYPE(v) == &minisat_solver_type; }
static inline bool var_type_p(VALUE v) { return TYPE(v) == T_DATA && RTYPEDDATA_TYPE(v) == &minisat_var_type; }
static inline bool lit_type_p(VALUE v) { return TYPE(v) == T_DATA && RTYPEDDATA_TYPE(v) == &minisat_lit_type; }

static inline VALUE lbool2value(Minisat::lbool b) {
  using Minisat::lbool;
  if (b == l_True) {
    return Qtrue;
  } else if (b == l_False) {
    return Qfalse;
  } else {
    return Qnil;
  }
}

static void check_solver(VALUE s1, VALUE s2, VALUE v)
{
  if (s1 != s2) {
    rb_raise(rb_eArgError, "%s created by a different solver", rb_obj_classname(v));
  }
}

static VALUE new_lit(const Minisat::Lit& lit, VALUE solver)
{
  LitWrapper *l = ALLOC(LitWrapper);
  l->lit = lit;
  l->solver = solver;
  return TypedData_Wrap_Struct(rb_cLit, &minisat_lit_type, l);
}

/*
 * Document-class: MiniSat::Solver
 *
 * MiniSat solver
 */

void minisat_solver_free(void *solver)
{
  delete static_cast<Minisat::Solver *>(solver);
}

size_t minisat_solver_memsize(const void *solver)
{
  if (solver) {
    return sizeof(Minisat::Solver);
  } else {
    return 0;
  }
}

VALUE minisat_solver_alloc(VALUE klass)
{
  Minisat::Solver *solver = ALLOC(Minisat::Solver);
  new (solver) Minisat::Solver;
  return TypedData_Wrap_Struct(klass, &minisat_solver_type, solver);
}

/*
 * call-seq: add_clause(lits)
 *
 * Add a new clause
 *
 * @param [Array<MiniSat::Lit, MiniSat::Var>] lits A clause that should be satisfied
 * @return [self]
 */
VALUE minisat_solver_add_clause(VALUE self, VALUE lits)
{
  lits = rb_convert_type(lits, T_ARRAY, "Array", "to_ary");
  const VALUE *ary = RARRAY_PTR(lits);
  const int len = RARRAY_LEN(lits);
  Minisat::vec<Minisat::Lit> c;
  for (int i = 0; i < len; i++) {
    if (var_type_p(ary[i])) {
      VarWrapper *v;
      TypedData_Get_Struct(ary[i], VarWrapper, &minisat_var_type, v);
      check_solver(self, v->solver, ary[i]);
      Minisat::Lit lit = Minisat::mkLit(v->var);
      c.push(lit);
    } else if (lit_type_p(ary[i])) {
      LitWrapper *l;
      TypedData_Get_Struct(ary[i], LitWrapper, &minisat_lit_type, l);
      check_solver(self, l->solver, ary[i]);
      c.push(l->lit);
    } else {
      rb_raise(rb_eTypeError, "wrong clause element type %s (only MiniSat::Var and MiniSat::Lit are allowed)", rb_obj_classname(ary[i]));
    }
  }

  Minisat::Solver *solver;
  TypedData_Get_Struct(self, Minisat::Solver, &minisat_solver_type, solver);
  solver->addClause_(c);
  return self;
}

/*
 * call-seq: solve
 *
 * Solves SAT.
 * Returns MiniSat::Model if satisfied. Otherwise returns nil
 *
 * @return [<MiniSat::Model>, nil] a model that satisfies given clauses
 *
 */
VALUE minisat_solver_solve(VALUE self)
{
  using Minisat::lbool;

  Minisat::Solver *solver;
  TypedData_Get_Struct(self, Minisat::Solver, &minisat_solver_type, solver);
  if (!solver->simplify()) {
    return Qfalse;
  }
  Minisat::vec<Minisat::Lit> dummy;
  if (solver->solveLimited(dummy) != l_True) {
    return Qnil;
  }

  Model *model = ALLOC(Model);
  model->solver = self;
  model->size = solver->model.size();
  model->ary = ALLOC_N(Minisat::lbool, model->size);
  for (int i = 0; i < model->size; i++) {
    model->ary[i] = solver->model[i];
  }
  return Data_Wrap_Struct(rb_cModel, minisat_model_mark, minisat_model_free, model);
}

/* Document-class: MiniSat::Var
 *
 * Variable used by MiniSat::Solver
 */

void minisat_var_mark(void *wrapper)
{
  VarWrapper *v = static_cast<VarWrapper *>(wrapper);
  rb_gc_mark(v->solver);
}

void minisat_var_free(void *wrapper)
{
  free(wrapper);
}

size_t minisat_var_memsize(const void *wrapper)
{
  if (wrapper) {
    return sizeof(VarWrapper);
  } else {
    return 0;
  }
}

VALUE minisat_var_alloc(VALUE klass)
{
  VarWrapper *v = ALLOC(VarWrapper);
  v->solver = Qnil;
  return TypedData_Wrap_Struct(klass, &minisat_var_type, v);
}

/*
 * call-seq: new(solver)
 *
 * Creates a new variable used by the solver
 *
 * @param [MiniSat::Solver] solver
 * @return [MiniSat::Var]
 */
VALUE minisat_var_initialize(VALUE self, VALUE solver)
{
  VarWrapper *v;
  TypedData_Get_Struct(self, VarWrapper, &minisat_var_type, v);
  if (!solver_type_p(solver)) {
    rb_raise(rb_eTypeError, "%s: not a MiniSat::Solver", rb_obj_classname(solver));
  }
  Minisat::Solver *s;
  TypedData_Get_Struct(solver, Minisat::Solver, &minisat_solver_type, s);
  v->var = s->newVar();
  v->solver = solver;
  return self;
}

/*
 * call-seq: to_lit
 *
 * Convert to a positive literal.
 *
 * @return [MiniSat::Lit] literal
 */
VALUE minisat_var_to_lit(VALUE self)
{
  VarWrapper *v;
  TypedData_Get_Struct(self, VarWrapper, &minisat_var_type, v);
  return new_lit(Minisat::mkLit(v->var), v->solver);
}

/*
 * call-seq: to_i
 *
 * Returns its index (1-origin for DIMACS format)
 *
 * @return [Fixnum]
 */
VALUE minisat_var_to_i(VALUE self)
{
  VarWrapper *v;
  TypedData_Get_Struct(self, VarWrapper, &minisat_var_type, v);
  return INT2FIX(Minisat::toInt(v->var) + 1);
}

/*
 * call-seq: ==
 *
 * Returns true if they represent the same variable
 *
 * @return [Boolean]
 */
VALUE minisat_var_eq(VALUE self, VALUE arg)
{
  if (!var_type_p(arg)) {
    return Qfalse;
  }
  VarWrapper *v1, *v2;
  TypedData_Get_Struct(self, VarWrapper, &minisat_var_type, v1);
  TypedData_Get_Struct(arg, VarWrapper, &minisat_var_type, v2);
  if (v1->var == v2->var) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

/* Document-class: MiniSat::Lit
 *
 * Literal used by MiniSat::Solver
 */

void minisat_lit_mark(void *wrapper)
{
  LitWrapper *l = static_cast<LitWrapper *>(wrapper);
  rb_gc_mark(l->solver);
}

void minisat_lit_free(void *wrapper)
{
  free(wrapper);
}

size_t minisat_lit_memsize(const void *wrapper)
{
  if (wrapper) {
    return sizeof(LitWrapper);
  } else {
    return 0;
  }
}

/*
 * call-seq: positive?
 *
 * Returns true if it is a positive literal
 */
VALUE minisat_lit_positive_p(VALUE self)
{
  LitWrapper *l;
  TypedData_Get_Struct(self, LitWrapper, &minisat_lit_type, l);
  if (Minisat::sign(l->lit)) {
    return Qfalse;
  } else {
    return Qtrue;
  }
}

/*
 * call-seq: to_var
 *
 * Convert to a variable
 *
 * @return [MiniSat::Var]
 */
VALUE minisat_lit_to_var(VALUE self)
{
  LitWrapper *l;
  TypedData_Get_Struct(self, LitWrapper, &minisat_lit_type, l);
  VarWrapper *v = ALLOC(VarWrapper);
  v->var = Minisat::var(l->lit);
  v->solver = l->solver;
  return TypedData_Wrap_Struct(rb_cVar, &minisat_var_type, v);
}

/*
 * call-seq: negative?
 *
 * Returns true if it is a negative literal
 */
VALUE minisat_lit_negative_p(VALUE self)
{
  LitWrapper *l;
  TypedData_Get_Struct(self, LitWrapper, &minisat_lit_type, l);
  if (Minisat::sign(l->lit)) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

/*
 * call-seq: -@
 *
 * Returns a negated literal
 *
 * @return [MiniSat::Lit]
 */
VALUE minisat_lit_neg(VALUE self)
{
  LitWrapper *l1, *l2;
  TypedData_Get_Struct(self, LitWrapper, &minisat_lit_type, l1);
  return new_lit(~l1->lit, l1->solver);
}

/*
 * call-seq: ==
 *
 * Returns true if they represent the same literal
 *
 * @return [Boolean]
 */
VALUE minisat_lit_eq(VALUE self, VALUE arg)
{
  if (!lit_type_p(arg)) {
    return Qfalse;
  }
  LitWrapper *l1, *l2;
  TypedData_Get_Struct(self, LitWrapper, &minisat_lit_type, l1);
  TypedData_Get_Struct(arg, LitWrapper, &minisat_lit_type, l2);
  if (l1->lit == l2->lit) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

/*
 * Document-class: MiniSat::Model
 *
 * Model generated by MiniSat::Solver
 */

void minisat_model_mark(void *model)
{
  rb_gc_mark(static_cast<Model *>(model)->solver);
}

void minisat_model_free(void *model)
{
  free(static_cast<Model *>(model)->ary);
  free(model);
}

/*
 * call-seq: [](var_or_lit)
 *
 * Returns true if the var_or_lit is true in this model
 *
 * @param [MiniSat::Lit, MiniSat::Var] var_or_lit variable or literal
 * @return [Boolean]
 */
VALUE minisat_model_ref(VALUE self, VALUE var)
{
  Model *model;
  Data_Get_Struct(self, Model, model);

  if (var_type_p(var)) {
    VarWrapper *v;
    TypedData_Get_Struct(var, VarWrapper, &minisat_var_type, v);
    check_solver(model->solver, v->solver, var);
    return lbool2value(model->ary[v->var]);
  } else if (lit_type_p(var)) {
    LitWrapper *l;
    TypedData_Get_Struct(var, LitWrapper, &minisat_lit_type, l);
    check_solver(model->solver, l->solver, var);
    return lbool2value(model->ary[Minisat::var(l->lit)] ^ Minisat::sign(l->lit));
  } else {
    rb_raise(rb_eTypeError, "wrong argument type %s (only MiniSat::Var and MiniSat::Lit are allowed", rb_obj_classname(var));
  }
}

/*
 * call-seq: size
 *
 * Returns the size of this model
 *
 * @return [Fixnum]
 */
VALUE minisat_model_size(VALUE self)
{
  Model *model;
  Data_Get_Struct(self, Model, model);
  return INT2FIX(model->size);
}

/*
 * call-seq: to_negative
 *
 * Returns a clause that denies this model.
 * This method is useful if you'd like to iterate over all models.
 *
 * @return [MiniSat::Model]
 */
VALUE minisat_model_to_negative(VALUE self)
{
  using Minisat::lbool;

  Model *model;
  Data_Get_Struct(self, Model, model);

  VALUE ary = rb_ary_new2(model->size);
  for (int i = 0; i < model->size; i++) {
    Minisat::Lit lit = Minisat::mkLit(i);
    if (model->ary[i] == l_True) {
      lit = ~lit;
    }
    rb_ary_store(ary, i, new_lit(lit, model->solver));
  }
  return ary;
}

void Init_minisat(void)
{
  rb_mMiniSat = rb_define_module("MiniSat");
  rb_cSolver = rb_define_class_under(rb_mMiniSat, "Solver", rb_cObject);
  rb_define_alloc_func(rb_cSolver, minisat_solver_alloc);
  rb_define_method(rb_cSolver, "add_clause", RUBY_METHOD_FUNC(minisat_solver_add_clause), 1);
  rb_define_method(rb_cSolver, "solve", RUBY_METHOD_FUNC(minisat_solver_solve), 0);

  rb_cVar = rb_define_class_under(rb_mMiniSat, "Var", rb_cObject);
  rb_define_alloc_func(rb_cVar, minisat_var_alloc);
  rb_define_method(rb_cVar, "initialize", RUBY_METHOD_FUNC(minisat_var_initialize), 1);
  rb_define_method(rb_cVar, "to_lit", RUBY_METHOD_FUNC(minisat_var_to_lit), 0);
  rb_define_method(rb_cVar, "to_i", RUBY_METHOD_FUNC(minisat_var_to_i), 0);
  rb_define_method(rb_cVar, "==", RUBY_METHOD_FUNC(minisat_var_eq), 1);

  rb_cLit = rb_define_class_under(rb_mMiniSat, "Lit", rb_cObject);
  rb_undef_method(CLASS_OF(rb_cLit), "new");
  rb_define_method(rb_cLit, "positive?", RUBY_METHOD_FUNC(minisat_lit_positive_p), 0);
  rb_define_method(rb_cLit, "negative?", RUBY_METHOD_FUNC(minisat_lit_negative_p), 0);
  rb_define_method(rb_cLit, "to_var", RUBY_METHOD_FUNC(minisat_lit_to_var), 0);
  rb_define_method(rb_cLit, "-@", RUBY_METHOD_FUNC(minisat_lit_neg), 0);
  rb_define_method(rb_cLit, "==", RUBY_METHOD_FUNC(minisat_lit_eq), 1);

  rb_cModel = rb_define_class_under(rb_mMiniSat, "Model", rb_cObject);
  rb_undef_method(CLASS_OF(rb_cModel), "new");
  rb_define_method(rb_cModel, "[]", RUBY_METHOD_FUNC(minisat_model_ref), 1);
  rb_define_method(rb_cModel, "size", RUBY_METHOD_FUNC(minisat_model_size), 0);
  rb_define_method(rb_cModel, "to_negative", RUBY_METHOD_FUNC(minisat_model_to_negative), 0);
}

#include "ruby.h"
#include "ruby/st.h"

#define BASE_HINT 200000

static VALUE cdict_new(VALUE self) {
  st_table *t = st_init_strtable_with_size(BASE_HINT);
  VALUE obj = Data_Wrap_Struct(self, NULL, st_free_table, t);
  return obj;
}

static VALUE cdict_include(VALUE self, VALUE key) {
  st_table *t;
  Data_Get_Struct(self, st_table, t);
  return (st_is_member(t, key) ? Qtrue : Qfalse);
}

static VALUE cdict_add(VALUE self, VALUE key) {
  st_table *t;
  Data_Get_Struct(self, st_table, t);
  st_insert(t, key, 1);
  return Qnil;
}

static VALUE cdict_delete(VALUE self, VALUE key) {
  st_table *t;
  st_data_t ktmp = (st_data_t)key, val;
  Data_Get_Struct(self, st_table, t);
  st_delete(t, &ktmp, &val);
  return Qnil;
}

void Init_cdict(void) {
  VALUE mDat = rb_define_module("Dat");
  VALUE cDict = rb_define_class_under(mDat, "CDict", rb_cObject);
  rb_define_singleton_method(cDict, "new", cdict_new, 0);
  rb_define_method(cDict, "include?", cdict_include, 1);
  rb_define_method(cDict, "add", cdict_add, 1);
  rb_define_method(cDict, "delete", cdict_delete, 1);
}


#include <string.h>
#include "ruby.h"
#include "table.h"

#if !defined(RSTRING_LEN)
# define RSTRING_LEN(x) (RSTRING(x)->len)
# define RSTRING_PTR(x) (RSTRING(x)->ptr)
#endif

static int cmpstr(const void *x, const void *y) {
  return strcmp((char *)x, (char *)y);
}

static unsigned long hashstr(const void *key) {
  char *str = (char *)key;
  unsigned long hash = 5381;
  int c;

  while (c = *str++)
    hash = ((hash << 5) + hash) + c;

  return hash;
}

static VALUE cdict_new(VALUE self) {
  Table t = table_new(0, cmpstr, hashstr); /* TODO change hint to larger */
  return Data_Wrap_Struct(self, NULL, table_free, &t);
}

static VALUE cdict_include(VALUE self, VALUE key) {
  Table *t;
  Data_Get_Struct(self, Table, t);
  int *val = table_get(*t, StringValueCStr(key));
  if (val) {
    return Qtrue;
  } else {
    return Qnil;
  }
}

static VALUE cdict_add(VALUE self, VALUE key) {
  Table *t;
  int v = 1;
  Data_Get_Struct(self, Table, t);
  table_put(*t, StringValueCStr(key), &v);
  return Qnil;
}

static VALUE cdict_delete(VALUE self, VALUE key) {
  Table *t;
  Data_Get_Struct(self, Table, t);
  table_remove(*t, StringValueCStr(key));
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


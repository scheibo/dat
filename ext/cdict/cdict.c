/**
 * Copyright (c) 1994,1995,1996,1997 by David R. Hanson.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies
 * or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
 * OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * <http://www.opensource.org/licenses/mit-license.php>
 */

#include <limits.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "ruby.h"

struct T {
  int size;
  int (*cmp)(const void *x, const void *y);
  unsigned long (*hash)(const void *key);
  int length;
  unsigned timestamp;
  struct binding {
    struct binding *link;
    const void *key;
    void *value;
  } **buckets;
};
typedef struct T *Table;

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

Table table_new(int hint,
    int cmp(const void *x, const void *y),
    unsigned long hash(const void *key)) {
  Table table;
  int i;
  static int primes[] = { 509, 509, 1021, 2053, 4093,
    8191, 16381, 32771, 65521, 131071, 262139, 524287,
    1048573, INT_MAX };
  for (i = 1; primes[i] < hint; i++) ;
  table = malloc(sizeof (*table) +
      primes[i-1]*sizeof (table->buckets[0]));
  table->size = primes[i-1];
  table->cmp  = cmp;
  table->hash = hash;
  table->buckets = (struct binding **)(table + 1);
  for (i = 0; i < table->size; i++)
    table->buckets[i] = NULL;
  table->length = 0;
  table->timestamp = 0;
  return table;
}

void *table_get(Table table, const void *key) {
  int i;
  struct binding *p;
  i = (int)(*table->hash)(key)%table->size;
  for (p = table->buckets[i]; p; p = p->link) {
    if ((*table->cmp)(key, p->key) == 0) {
      break;
    }
  }

  return p ? p->value : NULL;
}

void *table_put(Table table, const void *key, void *value) {
  int i;
  struct binding *p;
  void *prev;
  i = (int)(*table->hash)(key)%table->size;
  for (p = table->buckets[i]; p; p = p->link) {
    if ((*table->cmp)(key, p->key) == 0) {
      break;
    }
  }
  if (p == NULL) {
    p = malloc(sizeof *p);
    p->key = key;
    p->link = table->buckets[i];
    table->buckets[i] = p;
    table->length++;
    prev = NULL;
  } else {
    prev = p->value;
  }
  p->value = value;
  table->timestamp++;
  return prev;
}

void *table_remove(Table table, const void *key) {
  int i;
  struct binding **pp;
  table->timestamp++;
  i = (int)(*table->hash)(key)%table->size;
  for (pp = &table->buckets[i]; *pp; pp = &(*pp)->link) {
    if ((*table->cmp)(key, (*pp)->key) == 0) {
      struct binding *p = *pp;
      void *value = p->value;
      *pp = p->link;
      free(p);
      table->length--;
      return value;
    }
  }
  return NULL;
}

void table_free(Table *table) {
  if ((*table)->length > 0) {
    int i;
    struct binding *p, *q;
    for (i = 0; i < (*table)->size; i++) {
      for (p = (*table)->buckets[i]; p; p = q) {
        q = p->link;
        free(p);
      }
    }
  }
  free(*table);
}

static VALUE cdict_new(VALUE self) {
  Table t = table_new(0, cmpstr, hashstr); /* TODO change hint to larger */
  return Data_Wrap_Struct(self, NULL, table_free, &t);
}

static VALUE cdict_include(VALUE self, VALUE key) {
  Table *t;
  Data_Get_Struct(self, Table, t);
  void *val = table_get(*t, StringValueCStr(key));
  if (val) {
    return Qtrue;
  } else {
    return Qnil;
  }
}

static VALUE cdict_add(VALUE self, VALUE key) {
  Table *t;
  Data_Get_Struct(self, Table, t);
  int v = 1;
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


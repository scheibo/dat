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
#include "table.h"

#define T Table
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

static int cmpatom(const void *x, const void *y) {
  return x != y;
}

static unsigned long hashatom(const void *key) {
  return (unsigned long)key>>2;
}

T table_new(int hint,
    int cmp(const void *x, const void *y),
    unsigned long hash(const void *key)) {
  T table;
  int i;
  static int primes[] = { 509, 509, 1021, 2053, 4093,
    8191, 16381, 32771, 65521, 131071, 262139, 524287,
    1048573, INT_MAX };
  for (i = 1; primes[i] < hint; i++) ;
  table = malloc(sizeof (*table) +
      primes[i-1]*sizeof (table->buckets[0]));
  table->size = primes[i-1];
  table->cmp  = cmp  ?  cmp : cmpatom;
  table->hash = hash ? hash : hashatom;
  table->buckets = (struct binding **)(table + 1);
  for (i = 0; i < table->size; i++)
    table->buckets[i] = NULL;
  table->length = 0;
  table->timestamp = 0;
  return table;
}

void *table_get(T table, const void *key) {
  int i;
  struct binding *p;
  i = (int)(*table->hash)(key)%table->size;
  for (p = table->buckets[i]; p; p = p->link)
    if ((*table->cmp)(key, p->key) == 0)
      break;

  return p ? p->value : NULL;
}

void *table_put(T table, const void *key, void *value) {
  int i;
  struct binding *p;
  void *prev;
  i = (int)(*table->hash)(key)%table->size;
  for (p = table->buckets[i]; p; p = p->link)
    if ((*table->cmp)(key, p->key) == 0)
      break;
  if (p == NULL) {
    p = malloc(sizeof *p);
    p->key = key;
    p->link = table->buckets[i];
    table->buckets[i] = p;
    table->length++;
    prev = NULL;
  } else
    prev = p->value;
  p->value = value;
  table->timestamp++;
  return prev;
}

int table_length(T table) {
  return table->length;
}

void table_map(T table,
    void apply(const void *key, void **value, void *cl),
    void *cl) {
  int i;
  unsigned stamp;
  struct binding *p;
  stamp = table->timestamp;
  for (i = 0; i < table->size; i++)
    for (p = table->buckets[i]; p; p = p->link) {
      apply(p->key, &p->value, cl);
    }
}

void *table_remove(T table, const void *key) {
  int i;
  struct binding **pp;
  table->timestamp++;
  i = (int)(*table->hash)(key)%table->size;
  for (pp = &table->buckets[i]; *pp; pp = &(*pp)->link)
    if ((*table->cmp)(key, (*pp)->key) == 0) {
      struct binding *p = *pp;
      void *value = p->value;
      *pp = p->link;
      free(p);
      table->length--;
      return value;
    }
  return NULL;
}

void **table_to_array(T table, void *end) {
  int i, j = 0;
  void **array;
  struct binding *p;
  array = malloc((2*table->length + 1)*sizeof (*array));
  for (i = 0; i < table->size; i++)
    for (p = table->buckets[i]; p; p = p->link) {
      array[j++] = (void *)p->key;
      array[j++] = p->value;
    }
  array[j] = end;
  return array;
}

void table_free(T *table) {
  if ((*table)->length > 0) {
    int i;
    struct binding *p, *q;
    for (i = 0; i < (*table)->size; i++)
      for (p = (*table)->buckets[i]; p; p = q) {
        q = p->link;
        free(p);
      }
  }
  free(*table);
}

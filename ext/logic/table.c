#include <limits.h>
#include <stddef.h>
#include <stdlib.h>
#include "table.h"

#define T Table
struct T {
  int size;
  int (*cmp)(const void *x, const void *y);
  unsigned (*hash)(const void *key);
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

/* Need string.h */ /*
static int cmpstr(const void *x, const void *y) {
  return strcmp((char *)x, (char *)y);
}

static unsigned hashstr(const void *key) {
  char *str = (char *)key;
  unsigned long hash = 5381;
  int c;

  while (c = *str++)
    hash = ((hash << 5) + hash) + c;

  return hash;
}
*/

static unsigned hashatom(const void *key) {
  return (unsigned long)key>>2;
}

T table_new(int hint,
    int cmp(const void *x, const void *y),
    unsigned hash(const void *key)) {
  T table;
  int i;
  static int primes[] = { 509, 509, 1021, 2053, 4093,
    8191, 16381, 32771, 65521, INT_MAX };
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
  i = (*table->hash)(key)%table->size;
  for (p = table->buckets[i]; p; p = p->link)
    if ((*table->cmp)(key, p->key) == 0)
      break;

  return p ? p->value : NULL;
}

void *table_put(T table, const void *key, void *value) {
  int i;
  struct binding *p;
  void *prev;
  i = (*table->hash)(key)%table->size;
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
  i = (*table->hash)(key)%table->size;
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

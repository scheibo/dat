#include <ruby.h>
#include <string.h>
#include <stdlib.h>

#define MIN(x, y) (((x) < (y)) ? (x) : (y))

#if !defined(RSTRING_LEN)
# define RSTRING_LEN(x) (RSTRING(x)->len)
# define RSTRING_PTR(x) (RSTRING(x)->ptr)
#endif

static ID id_get;

/* Helper function for c substrings */
static char* substr(char *word, long start, long end) {
  char *to = malloc((end-start) * sizeof(char));
  strncpy(to, word+start, end);
  return to;
}

/* Helper function to add values to the results array */
static VALUE add_if_in_dict(VALUE dict, char *word, VALUE result) {
  VALUE w = rb_str_new_cstr(word);
  VALUE d = rb_funcall(dict, id_get, 1, w);
  if (!NIL_P(d)) {
    rb_ary_push(result, d);
  }
  return Qnil;
}

static VALUE perturb(VALUE class, VALUE str, VALUE dict, VALUE opt) {
  static const char *alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  /* Parse the options we are passed in */
  VALUE min_size = rb_hash_lookup2(opt, ID2SYM(rb_intern("min_size")), Qfalse);
  char add = rb_hash_lookup2(opt, ID2SYM(rb_intern("add")), Qtrue);
  char replace = rb_hash_lookup2(opt, ID2SYM(rb_intern("replace")), Qtrue);
  char delete = rb_hash_lookup2(opt, ID2SYM(rb_intern("delete")), Qtrue);

  char *word = StringValueCStr(str); /* word is assumed to already be uppercase */
  long size = RSTRING_LEN(str); /* should be strlen(word) */
  VALUE result = rb_ary_new();

  int i, k;
  char c, *start, *fin, *w;
  for(i = 0; i <= size; i++) {
    start = substr(word, 0, i);
    for(k = 0; c = alpha[k]; k++) {
      if (add) {
        fin = substr(word, i, size);
        w = malloc((size+2) * sizeof(char));
        strncpy(w, start, i);
        strncat(w, &c, 1);
        strncat(w, fin, size-i);
        add_if_in_dict(dict, w, result);
        free(w);
        free(fin);
      }
      if (i < size) {
        if (replace) {
          fin = substr(word, i+1, size);
          w = malloc((size+1) * sizeof(char));
          strncpy(w, start, i);
          strncat(w, &c, 1);
          strncat(w, fin, size-i-1);
          add_if_in_dict(dict, w, result);
          free(w);
          free(fin);
        }
      }
    }
    if (i < size && delete && (!min_size || (size > FIX2LONG(min_size)))) {
      fin = substr(word, i+1, size);
      w = malloc(size * sizeof(char));
      strncpy(w, start, i);
      strncat(w, fin, size-i-1);
      add_if_in_dict(dict, w, result);
      free(w);
      free(fin);
    }
    free(start);
  }

  return result;
}

static VALUE levenshtein(VALUE class, VALUE a, VALUE b) {
  int i, j;
  char *s = StringValueCStr(a);
  char *t = StringValueCStr(b);
  long m = RSTRING_LEN(a);
  long n = RSTRING_LEN(b);

  /* for all i and j, d[i,j] will hold the Levenshtein distance between
   * the first i characters of s and the first j characters of t;
   * note that d has (m+1)x(n+1) values */
  long **d = malloc((m+1) * sizeof(long *));
  for(i = 0; i < m; i++) {
    d[i] = malloc((n+1) * sizeof(long));
  }

  for (i = 0; i <= m; i++) {
    d[i][0] = 0;
    for (j = 0; j <= n; j++) {
      d[0][j] = 0;
    }
  }

  for (j = 1; j <= n; j++) {
    for (i = 1; i <= m; i++) {
      if (s[i-1] == t[j-1]) {
        d[i][j] = d[i-1][j-1];
      } else {               /* delete */     /* insert */      /* replace */
        d[i][j] = MIN( MIN((d[i-1][j] + 1), (d[i][j-1] + 1)), (d[i-1][j-1] + 1) );
      }
    }
  }

  VALUE val = LONG2FIX(d[m][n]);

  for(i = 0; i <= m; i++) {
    free(d[i]);
  }
  free(d);

  return val;
}

void Init_logic(void) {
  VALUE mDat = rb_define_module("Dat");
  VALUE cLogic = rb_define_class_under(mDat, "Logic", rb_cObject);
  rb_define_singleton_function(cLogic, "perturb", perturb, 3);
  rb_define_singleton_function(cLogic, "levenshtein", levenshtein, 2);
  id_get = rb_intern("[]");
}

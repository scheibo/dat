#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#include "ruby.h"

#define MIN(x, y) (((x) < (y)) ? (x) : (y))

#define ASCII_A 65
#define ALPHABET_SIZE 26

/* only allow strings up to length of 30 */
#define SIZE_BYTES 32
/* save space by storing the string lengths in a small int */
typedef int8_t size;

#if !defined(RSTRING_LEN)
# define RSTRING_LEN(x) (RSTRING(x)->len)
# define RSTRING_PTR(x) (RSTRING(x)->ptr)
#endif

static ID id_get;
static const char *alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

/* Helper function to add values to the results array */
static VALUE add_if_in_dict(VALUE dict, char *word, VALUE result) {
  VALUE w = rb_str_new_cstr(word);
  VALUE d = rb_funcall(dict, id_get, 1, w);
  if (!NIL_P(d)) rb_ary_push(result, d);
  return Qnil;
}

/* precondition: str and dict are not nil */
static VALUE perturb(int argc, VALUE *argv, VALUE class) {
  VALUE str, dict, opt;
  rb_scan_args(argc, argv, "21", &str, &dict, &opt);
  if (NIL_P(opt)) opt = rb_hash_new();

  VALUE min_size = rb_hash_lookup2(opt, ID2SYM(rb_intern("min_size")), Qfalse);

  char start[SIZE_BYTES], fin[SIZE_BYTES], w[SIZE_BYTES];

  char *word = StringValueCStr(str); /* word is assumed to already be uppercase */
  size len = RSTRING_LEN(str); /* should be strlen(word) */
  VALUE result = rb_ary_new();

  char add = RTEST(rb_hash_lookup2(opt, ID2SYM(rb_intern("add")), Qtrue));
  char replace = RTEST(rb_hash_lookup2(opt, ID2SYM(rb_intern("replace")), Qtrue));
  char delete = RTEST(rb_hash_lookup2(opt, ID2SYM(rb_intern("delete")), Qtrue));

  size i, j;
  char c;
  for(i = 0; i <= len; i++) {
    strncpy(start, word, i);
    start[i] = '\0';
    for(j = 0; c = alpha[j]; j++) {
      if (add) {
        strncpy(fin, word+i, len+1);
        strncpy(w, start, i+1);
        strncat(w, &c, 1);
        strncat(w, fin, len-i);
        add_if_in_dict(dict, w, result);
      }
      if (i < len) {
        if (replace) {
          (i+1 == len) ? strncpy(fin, "", 2) : strncpy(fin, word+i+1, len+1);
          strncpy(w, start, i+1);
          strncat(w, &c, 1);
          strncat(w, fin, len-i-1);
          w[len+1] = '\0';
          if (strncmp(word, w, len)) {
            add_if_in_dict(dict, w, result);
          }
        }
      }
    }
    if (i < len && delete && (!min_size || (len > FIX2LONG(min_size)))) {
      (i+1 == len) ? strncpy(fin, "", 2) : strncpy(fin, word+i+1, len+1);
      strncpy(w, start, i+1);
      strncat(w, fin, len-i-1);
      w[len] = '\0';
      add_if_in_dict(dict, w, result);
    }
  }

  return result;
}

/* precondition: a and b not nil and the words are uppercase */
static VALUE damlev(VALUE class, VALUE a, VALUE b) {
  size i, j, w, x, y, z;
  char *s = StringValueCStr(a);
  char *t = StringValueCStr(b);
  size m = (size) RSTRING_LEN(a);
  size n = (size) RSTRING_LEN(b);

  if (!m) return INT2FIX(n);
  if (!n) return INT2FIX(m);

  size h[SIZE_BYTES][SIZE_BYTES];
  size inf = m + n;
  h[0][0] = inf;
  for (i = 0; i <= m; i++) { h[i+1][1] = i; h[i+1][0] = inf; }
  for (j = 0; j <= n; j++) { h[1][j+1] = j; h[0][j+1] = inf; }

  size da[ALPHABET_SIZE];
  for (i = 0; i < ALPHABET_SIZE; i++) {
    da[i] = 0;
  }

  size db, i1, j1, d;
  for (i = 1; i <= m; i++) {
    db = 0;
    for (j = 1; j <= n; j++) {
      i1 = da[t[j-1]-ASCII_A];
      j1 = db;
      d = ( (s[i-1] == t[j-1]) ? 0 : 1);
      if (!d) {
        db = j;
      }
      w = h[i][j]+d; x = h[i+1][j] + 1; y = h[i][j+1]+1; z = h[i1][j1] + (i-i1-1) + 1 + (j-j1-1);
      h[i+1][j+1] = MIN( MIN( MIN(w, x), y ), z );
    }
    da[s[i-1]-ASCII_A] = i;
  }

  VALUE val = INT2FIX(h[m+1][n+1]);
  return val;
}

static VALUE leven(VALUE class, VALUE a, VALUE b) {
  size i, j;
  char *s = StringValueCStr(a);
  char *t = StringValueCStr(b);
  size m = (size) RSTRING_LEN(a);
  size n = (size) RSTRING_LEN(b);

  /* for all i and j, d[i,j] will hold the Levenshtein distance between
   * the first i characters of s and the first j characters of t;
   * note that d has (m+1)x(n+1) values */
  size d[SIZE_BYTES][SIZE_BYTES];

  for (i = 0; i <= m; i++) {
    d[i][0] = i;
    for (j = 0; j <= n; j++) {
      d[0][j] = j;
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

  VALUE val = INT2FIX(d[m][n]);
  return val;
}

void Init_logic(void) {
  VALUE mDat = rb_define_module("Dat");
  VALUE cLogic = rb_define_class_under(mDat, "Logic", rb_cObject);
  rb_define_singleton_method(cLogic, "perturb", perturb, -1);
  rb_define_singleton_method(cLogic, "leven", leven, 2);
  rb_define_singleton_method(cLogic, "damlev", damlev, 2);
  id_get = rb_intern("[]");
}

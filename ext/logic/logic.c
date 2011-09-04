#include <ruby.h>
#include <string.h>
#include <stdlib.h>

#define MIN(x, y) (((x) < (y)) ? (x) : (y))
#define ASCII_A 65
#define ALPHABET_SIZE 26

#if !defined(RSTRING_LEN)
# define RSTRING_LEN(x) (RSTRING(x)->len)
# define RSTRING_PTR(x) (RSTRING(x)->ptr)
#endif

static ID id_get;
static const char *alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

/* Helper function for c substrings */
static char* substr(char *word, long start, long end) {
  char *to = malloc((end-start) * sizeof(char));
  strncpy(to, word+start, end);
  return to;
}

/* Helper to create a 2 dimensional array */
static long** alloc2d(long a, long b) {
  long i;
  long **d = malloc(a * sizeof(long *));
  for(i = 0; i < a; i++) {
    d[i] = malloc(b * sizeof(long));
  }
  return d;
}

/* Helper to free a 2 dimensional array */
static void free2d(long **d, long size) {
  long i;
  for(i = 0; i < size; i++) {
    free(d[i]);
  }
  free(d);
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

/*static VALUE perturb(VALUE class, VALUE str, VALUE dict, VALUE opt) { */
static VALUE perturb(int argc, VALUE *argv, VALUE class) {
  VALUE str, dict, opt;
  rb_scan_args(argc, argv, "21", &str, &dict, &opt);

  if NIL_P(opt) {
    opt = rb_hash_new();
  }

  /* Parse the options we are passed in */
  VALUE min_size = rb_hash_lookup2(opt, ID2SYM(rb_intern("min_size")), Qfalse);
  char add = rb_hash_lookup2(opt, ID2SYM(rb_intern("add")), Qtrue);
  char replace = rb_hash_lookup2(opt, ID2SYM(rb_intern("replace")), Qtrue);
  char delete = rb_hash_lookup2(opt, ID2SYM(rb_intern("delete")), Qtrue);

  char *word = StringValueCStr(str); /* word is assumed to already be uppercase */
  long size = RSTRING_LEN(str); /* should be strlen(word) */
  VALUE result = rb_ary_new();

  long i, j;
  char c, *start, *fin, *w;
  for(i = 0; i <= size; i++) {
    start = substr(word, 0, i);
    for(j = 0; c = alpha[j]; j++) {
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

/* precondition: a and b not nil and the words are uppercase */
static VALUE damlev(VALUE class, VALUE a, VALUE b) {
  long i, j, w, x, y, z;
  char *s = StringValueCStr(a);
  char *t = StringValueCStr(b);
  long m = RSTRING_LEN(a);
  long n = RSTRING_LEN(b);

  if (!m) return LONG2FIX(n);
  if (!n) return LONG2FIX(m);

  long **h = alloc2d(m+2, n+2);
  long inf = m + n;
  h[0][0] = inf;
  for (i = 0; i <= m; i++) { h[i+1][1] = i; h[i+1][0] = inf; }
  for (j = 0; j <= n; j++) { h[1][j+1] = j; h[0][j+1] = inf; }

  long da[ALPHABET_SIZE];
  for (i = 0; i < ALPHABET_SIZE; i++) {
    da[i] = 0;
  }

  long db, i1, j1, d;
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

  VALUE val = LONG2FIX(h[m+1][n+1]);
  free2d(h, m+2);
  return val;
}

static VALUE leven(VALUE class, VALUE a, VALUE b) {
  long i, j;
  char *s = StringValueCStr(a);
  char *t = StringValueCStr(b);
  long m = RSTRING_LEN(a);
  long n = RSTRING_LEN(b);

  /* for all i and j, d[i,j] will hold the Levenshtein distance between
   * the first i characters of s and the first j characters of t;
   * note that d has (m+1)x(n+1) values */
  long **d = alloc2d(m+1, n+1);

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

  VALUE val = LONG2FIX(d[m][n]);
  free2d(d, m+1);
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

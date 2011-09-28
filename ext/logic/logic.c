#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#include "ruby.h"

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

#define ASCII_A 65
#define ALPHABET_SIZE 26

/* only allow strings up to length of 30 */
#define SIZE_BYTES 32
/* save space by storing the string lengths in a small int */
typedef int8_t size;

#if !defined(RSTRING_LEN)
#define RSTRING_LEN(x) (RSTRING(x)->len)
#define RSTRING_PTR(x) (RSTRING(x)->ptr)
#endif

/* Use these instead of using const_get */
#define MIN_SIZE 3
#define WEIGHT_THRESHOLD 0.7
#define NUM_CHARS 4

static ID id_get;
static ID id_reject;
static const char *alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

static VALUE init(int argc, VALUE *argv, VALUE self) {
  VALUE dict, opt, add, replace, delete, transpose;
  rb_scan_args(argc, argv, "11", &dict, &opt);
  if (NIL_P(opt)) opt = rb_hash_new();

  rb_iv_set(self, "@dict", dict);

  add = rb_hash_lookup2(opt, ID2SYM(rb_intern("add")), Qtrue);
  replace = rb_hash_lookup2(opt, ID2SYM(rb_intern("replace")), Qtrue);
  delete = rb_hash_lookup2(opt, ID2SYM(rb_intern("delete")), Qtrue);
  transpose = rb_hash_lookup2(opt, ID2SYM(rb_intern("delete")), Qfalse);

  rb_iv_set(self, "@add", add);
  rb_iv_set(self, "@replace", replace);
  rb_iv_set(self, "@delete", delete) ;
  rb_iv_set(self, "@transpose", transpose);

  rb_iv_set(self, "@min_size", rb_hash_lookup2(opt, ID2SYM(rb_intern("min_size")), INT2FIX(MIN_SIZE)));

  rb_iv_set(self, "@cachable", (RTEST(add) && RTEST(replace) && RTEST(delete) && !RTEST(transpose) ? Qtrue : Qfalse));
  rb_iv_set(self, "@perturb_cache", rb_hash_new());

  return self;
}

/* Helper function to add values to the results array */
static void add_if_in_dict(VALUE dict, char *word, VALUE result) {
  VALUE w = rb_str_new_cstr(word);
  VALUE d = rb_funcall(dict, id_get, 1, w);
  if (RTEST(d)) rb_ary_push(result, d);
}

static VALUE reject_i(VALUE word, VALUE used) {
  return RTEST(rb_funcall(used, id_get, 1, word));
}

static VALUE perturb_impl(VALUE self, VALUE str) {
  char cacheable = RTEST(rb_iv_get(self, "@cachable"));
  VALUE cache = rb_iv_get(self, "@perturb_cache");
  if (cacheable) {
    VALUE r = rb_hash_aref(cache, str);
    if (RTEST(r)) return r;
  }

  VALUE dict = rb_iv_get(self, "@dict");
  size min_size = FIX2LONG(rb_iv_get(self, "@min_size"));

  char start[SIZE_BYTES], fin[SIZE_BYTES], w[SIZE_BYTES];

  char *word = StringValueCStr(str); /* word is assumed to already be uppercase */
  size len = RSTRING_LEN(str); /* should be strlen(word) */
  VALUE result = rb_ary_new();

  char add = RTEST(rb_iv_get(self, "@add"));
  char replace = RTEST(rb_iv_get(self, "@replace"));
  char delete = RTEST(rb_iv_get(self, "@delete"));
  char transpose = RTEST(rb_iv_get(self, "@transpose"));

  size i, j;
  char c;
  for(i = 0; i <= len; i++) {
    strncpy(start, word, i);
    start[i] = '\0';
    for(j = 0; c = alpha[j]; j++) {
      if (add && len >= min_size+1) {
        strncpy(fin, word+i, len+1);
        strncpy(w, start, i+1);
        strncat(w, &c, 1);
        strncat(w, fin, len-i);
        add_if_in_dict(dict, w, result);
      }
      if (i < len) {
        if (replace && len >= min_size) {
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
    if (i < len && delete && len > min_size) {
      (i+1 == len) ? strncpy(fin, "", 2) : strncpy(fin, word+i+1, len+1);
      strncpy(w, start, i+1);
      strncat(w, fin, len-i-1);
      w[len] = '\0';
      add_if_in_dict(dict, w, result);
    }
  }

  if (cacheable) {
    rb_hash_aset(cache, str, result);
  }

  return result;
}

static VALUE perturb(int argc, VALUE *argv, VALUE self) {
  VALUE str, used;
  rb_scan_args(argc, argv, "11", &str, &used);
  if (NIL_P(used)) used = rb_hash_new();
  VALUE result = rb_block_call(perturb_impl(self, str), id_reject, 0, 0, reject_i, used);
  return result;
}

static VALUE jaro_winkler(VALUE self, VALUE a, VALUE b) {
  int i, j, start, fin;
  char *s = StringValueCStr(a);
  char *t = StringValueCStr(b);
  size m = (size) RSTRING_LEN(a);
  size n = (size) RSTRING_LEN(b);
  if (m == 0) return rb_float_new(n == 0 ? 1.0 : 0.0);

  size range = MAX(0, (MAX(m,n)/2) - 1);

  char s_matched[SIZE_BYTES];
  char t_matched[SIZE_BYTES];
  for (i = 0; i < m; i++) s_matched[i] = 0;
  for (i = 0; i < n; i++) t_matched[i] = 0;

  int common = 0;
  for (i = 0; i < m; i++) {
    start = MAX(0,i-range);
    fin = MIN(i+range+1, n);
    for (j = start; j < fin; j++) {
      if (t_matched[j] || s[i] != t[j]) continue;
      s_matched[i] = 1;
      t_matched[j] = 1;
      common++;
      break;
    }
  }

  if (!common) return rb_float_new(0.0);

  int transposed = 0;
  j = 0;
  for (i = 0; i < m; i++) {
    if (!s_matched[i]) continue;
    while (!t_matched[j]) j++;
    if (s[i] != t[j]) transposed++;
    j++;
  }
  transposed /= 2;

  double weight = (((double)common/m) + ((double)common/n) + ((double)(common-transposed)/common)) / 3.0;
  if (weight <= WEIGHT_THRESHOLD) return rb_float_new(weight);

  int max = MIN(NUM_CHARS, MIN(m,n));
  int pos = 0;
  while (pos < max && s[pos] == t[pos]) pos++;
  if (pos == 0) return rb_float_new(weight);

  return rb_float_new(weight + 0.1 * pos * (1.0 - weight));
}

/* precondition: a and b not nil and the words are uppercase */
static VALUE damlev(VALUE self, VALUE a, VALUE b) {
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

static VALUE leven(VALUE self, VALUE a, VALUE b) {
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

  rb_const_set(cLogic, rb_intern("MIN_SIZE"), MIN_SIZE);
  rb_const_set(cLogic, rb_intern("WEIGHT_THRESHOLD"), WEIGHT_THRESHOLD);
  rb_const_set(cLogic, rb_intern("NUM_CHARS"), NUM_CHARS);

  rb_define_method(cLogic, "initialize", init, -1);
  rb_define_method(cLogic, "perturb", perturb, -1);
  rb_define_private_method(cLogic, "perturb_impl", perturb_impl, 1);
  rb_define_method(cLogic, "jaro_winkler", jaro_winkler, 2);
  rb_define_method(cLogic, "leven", leven, 2);
  rb_define_method(cLogic, "damlev", damlev, 2);
  id_get = rb_intern("[]");
  id_reject = rb_intern("reject");
}

#include <ruby.h>
#include <string.h>
#include <stdlib.h>

/* Helper function for c substrings */
static char* substr(char *word, long start, long end) {
  char* to = malloc(end-start);
  strncpy(to, word+start, end);
  return to;
}

/* Helper function to add values to the results array */
static VALUE add_if_in_dict(VALUE dict, char *word, VALUE result) {
  VALUE w = rb_str_new_cstr(word);
  VALUE d = rb_funcall(dict, rb_intern("[]"), 1, rb_str_new_cstr(word));
  if (d != Qnil) {
    rb_ary_push(result, w);
  }
  return Qnil;
}

static VALUE c_perturb(VALUE class, VALUE str, VALUE dict, VALUE opt) {
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
      fin = substr(word, i, size);
      if (add) {
        w = malloc(size+2); /* one for the null byte and one for the new character */
        strncpy(w, start, i);
        strncat(w, &c, 1);
        strncat(w, fin, size-i);
        add_if_in_dict(dict, w, result);
      }
      if (i < size) {
        fin = substr(word, i+1, size);
        if (replace) {
          w = malloc(size+1); /* extra for null byte */
          strncpy(w, start, i);
          strncat(w, &c, 1);
          strncat(w, fin, size-i-1);
          add_if_in_dict(dict, w, result);
        }
      }
    }
    if (i < size && delete && (!min_size || (size > NUM2INT(min_size)))) {
      w = malloc(size);
      strncpy(w, start, i);
      strncat(w, fin, size-i-1);
      add_if_in_dict(dict, w, result);
    }
  }

  return result;
}

void Init_dat(void) {
  VALUE Dat = rb_define_module("Dat");
  VALUE Logic = rb_define_class_under(Dat, "Logic", rb_cObject);
  rb_define_singleton_function(Logic, "c_perturb", c_perturb, 3);
}

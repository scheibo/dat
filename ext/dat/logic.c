#include <ruby.h>
#include <string.h>
#include <stdlib.h>

char *alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
int get_id = rb_intern("[]");


void Init_dat(void) {
  VALUE Dat = rb_define_module("Dat");
  VALUE Logic = rb_define_class_under(Dat, "Logic", rb_cObject);
  rb_define_singleton_function(Logic, "c_perturb", perturb, 2);
}

static VALUE c_perturb(VALUE class, VALUE str, VALUE dict, VALUE min_size) {
  int i, k;
  char c;
  char *word = RSTRING(str)->ptr;
  int size = RSTRING(str)->len;

  VALUE result = rb_ary_new();

  for(i = 0; i <= size; i++) {
    char *start = substr(word, 0, i);
    char *fin = substr(word, i, size);

    for(k = 0; c = alpha[k]; k++) {
      add_if_in_dict(dict, strncat(strncat(start, c, 1), fin, size-i), result);

      if (i < size) {
        fin = substr(word, i+1, size);
        add_if_in_dict(dict, strncat(strncat(start, c, 1), fin, size-i-1), result);
        if (min_size != Qnil && size-1 >= NUM2INT(min_size)) {
          add_if_in_dict(dict, strncat(start, fin, size-i-1), result);
        }
      }
    }
  }

  return result;
}

static char* substr(char *word, int start, int end) {
  char* to = malloc(end-start);
  strncpy(to, word+start, end);
  return to;
}

static char* add_if_in_dict(VALUE dict, char *word, VALUE result) {
  VALUE d = rb_funcall(dict, get_id, 1, rb_str_new2(word));
  if (d != Qnil) {
    rb_ary_push(result, w);
  }
}

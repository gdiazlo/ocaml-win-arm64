#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>

CAMLprim value arm64_sum10(value a, value b, value c, value d, value e,
                          value f, value g, value h, value i, value j)
{
  return Val_long(Long_val(a) + Long_val(b) + Long_val(c) + Long_val(d) +
                  Long_val(e) + Long_val(f) + Long_val(g) + Long_val(h) +
                  Long_val(i) + Long_val(j));
}

CAMLprim value arm64_sum10_bytecode(value *argv, int argc)
{
  (void) argc;
  return arm64_sum10(argv[0], argv[1], argv[2], argv[3], argv[4],
                     argv[5], argv[6], argv[7], argv[8], argv[9]);
}

CAMLprim double arm64_floats10(double a, double b, double c, double d, double e,
                             double f, double g, double h, double i, double j)
{
  return a + b + c + d + e + f + g + h + i + j;
}

CAMLprim value arm64_floats10_bytecode(value *argv, int argc)
{
  (void) argc;
  return caml_copy_double(arm64_floats10(
    Double_val(argv[0]), Double_val(argv[1]), Double_val(argv[2]),
    Double_val(argv[3]), Double_val(argv[4]), Double_val(argv[5]),
    Double_val(argv[6]), Double_val(argv[7]), Double_val(argv[8]),
    Double_val(argv[9])));
}

CAMLprim value arm64_callback_gc(value fn, value arg)
{
  CAMLparam2(fn, arg);
  CAMLlocal1(result);
  for (int i = 0; i < 20; i++) result = caml_callback(fn, arg);
  CAMLreturn(result);
}

CAMLprim value arm64_callback_raises(value fn)
{
  CAMLparam1(fn);
  CAMLlocal1(result);
  result = caml_callback_exn(fn, Val_unit);
  CAMLreturn(Val_bool(Is_exception_result(result)));
}

CAMLprim value arm64_raise_from_c(value unit)
{
  (void) unit;
  caml_failwith("raised from C");
}

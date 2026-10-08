#include <windows.h>
#include <stdio.h>
#ifndef __aarch64__
#error This probe must be compiled for native Windows ARM64
#endif

int main(void)
{
  typedef int (*plus_one_fn)(int);
  HMODULE dll = LoadLibraryW(L".\\baseline.dll");
  if (dll == NULL) {
    fprintf(stderr, "LoadLibrary failed: %lu\n", GetLastError());
    return 1;
  }
  plus_one_fn plus_one = (plus_one_fn)GetProcAddress(dll, "baseline_plus_one");
  if (plus_one == NULL || plus_one(41) != 42) {
    fprintf(stderr, "DLL export lookup/call failed\n");
    FreeLibrary(dll);
    return 1;
  }
  FreeLibrary(dll);
  puts("PASS native ARM64 Windows DLL: LoadLibrary, GetProcAddress, call, FreeLibrary");
  return 0;
}

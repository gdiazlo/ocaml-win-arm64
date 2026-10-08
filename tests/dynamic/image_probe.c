#include <windows.h>
#include <stdio.h>
int main(int argc, char **argv) {
  for (int i=1;i<argc;i++) {
    HMODULE m = LoadLibraryExA(argv[i], NULL, DONT_RESOLVE_DLL_REFERENCES);
    printf("%s: image=%p error=%lu\n", argv[i], m, m ? 0 : GetLastError());
    if(m) FreeLibrary(m);
  }
  return 0;
}

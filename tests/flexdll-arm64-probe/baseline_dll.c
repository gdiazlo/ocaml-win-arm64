#ifndef __aarch64__
#error This probe must be compiled for native Windows ARM64
#endif
__declspec(dllexport) int baseline_plus_one(int x) { return x + 1; }

#!/usr/bin/env bash
# Research probes only; does not patch FlexDLL or the working OCaml installation.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/scripts/common.sh"
cd "$ROOT"
export PATH="$OPAMROOT_UNIX/windows-arm64/bin:$ROOT/local/bin:$PATH"
PROBE=tests/flexdll-arm64-probe
(
  cd "$PROBE"
  clang -O2 -c references.c -o direct.o
  clang -O2 -DUSE_DLLIMPORT -c references.c -o import.o
  clang -c references.S -o assembly.o
  ocamlopt.exe -S -c native_references.ml
  llvm-readobj --file-headers --relocations --symbols \
    direct.o import.o assembly.o native_references.o > "$ROOT/logs/flexdll-arm64-relocations.txt"
  llvm-objdump -dr direct.o import.o assembly.o native_references.o \
    > "$ROOT/logs/flexdll-arm64-disassembly.txt"
  clang -O2 -shared baseline_dll.c -Wl,--out-implib,baseline.dll.a -o baseline.dll
  clang -O2 baseline_host.c -o baseline_host.exe
  ./baseline_host.exe
  file baseline.dll baseline_host.exe
)
clang -DMINGW -c sources/flexdll/flexdll.c -o "$PROBE/runtime.o"
clang -c sources/flexdll/flexdll_initer.c -o "$PROBE/initer.o"
file "$PROBE/"{runtime,initer}.o
STAGE=dist/staging/flexdll-inspection
rm -rf -- "$STAGE"
mkdir -p "$STAGE"
git -C sources/flexdll archive HEAD | tar -xf - -C "$STAGE"
make -C "$STAGE" -j1 flexlink.exe MSVC_DETECT=0 RC=windres \
  > logs/flexdll-arm64-bootstrap.log 2>&1
"$STAGE/flexlink.exe" -version
file "$STAGE/flexlink.exe"
"$STAGE/flexlink.exe" -chain ld -builtin -dump "$PROBE/assembly.o" \
  > logs/flexdll-arm64-coff-parser.log 2>&1
printf 'PASS ARM64 investigation probes; FlexDLL target support is not implemented yet.\n'

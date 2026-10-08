#!/usr/bin/env bash
# Unmodified upstream tests in the separate dynamic compiler build tree.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/scripts/common.sh"
cd "$ROOT"
BUILD=sources/ocaml-windows-arm64-dynamic
[[ -f "$BUILD/Makefile.config" ]] || { echo 'Run build-dynamic.sh first' >&2; exit 1; }
# Release archives omit tests via export-ignore. Copy the unchanged full clone's
# fixtures, never editing expected results to accommodate the port.
git -C sources/ocaml diff --quiet HEAD -- testsuite/tests
cp -a sources/ocaml/testsuite/tests "$BUILD/testsuite/"
# The standalone FlexDLL directory also contains flexdll.h and support objects
# needed by configure's external-FlexDLL probe (the compiler package vendors it).
export PATH="$ROOT/local-dynamic/flexdll:$OPAMROOT_UNIX/windows-arm64-dynlink/bin:$PATH"
unset OCAMLLIB CAMLLIB CAML_LD_LIBRARY_PATH OCAMLTOP_INCLUDE_PATH FLEXDIR
cd "$BUILD"
./configure --build=aarch64-w64-mingw32 --host=aarch64-w64-mingw32 \
  --prefix="$(cygpath -am "$ROOT/local-dynamic")" --enable-shared \
  --disable-dependency-generation --with-relative-libdir \
  --with-additional-stublibsdir --enable-runtime-search \
  --enable-runtime-search-target=fallback --enable-ocamltest \
  CC=clang AR=llvm-ar RANLIB=llvm-ranlib \
  > "$ROOT/logs/upstream-dynamic-configure.log" 2>&1
make -j2 ocamltest.opt testsuite/tools/expect.exe \
  > "$ROOT/logs/upstream-dynamic-build.log" 2>&1
cd testsuite
status=0
make one LIST=../../../tests/upstream-dynamic-list.txt \
  > "$ROOT/logs/upstream-dynamic-tests.log" 2>&1 || status=$?
tail -22 "$ROOT/logs/upstream-dynamic-tests.log"
if grep -Eq ' 0 tests considered|Fatal error: exception Sys_error' "$ROOT/logs/upstream-dynamic-tests.log"; then
  exit 1
fi
exit "$status"

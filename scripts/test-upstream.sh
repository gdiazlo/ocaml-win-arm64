#!/usr/bin/env bash
# Selected unmodified upstream tests. Requires the full sources/ocaml clone.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT/sources/ocaml"
PREFIX_WIN=$(cygpath -am "$ROOT/local")
./configure --build=aarch64-w64-mingw32 --host=aarch64-w64-mingw32 \
  --prefix="$PREFIX_WIN" --disable-shared --disable-dependency-generation \
  --enable-ocamltest CC=clang AR=llvm-ar RANLIB=llvm-ranlib \
  > "$ROOT/logs/ocaml-test-configure.log" 2>&1
make -j2 ocamltest.opt testsuite/tools/expect.exe \
  > "$ROOT/logs/ocaml-test-build.log" 2>&1
cd testsuite
make one LIST=../../../tests/upstream-list.txt \
  > "$ROOT/logs/upstream-tests.log" 2>&1
tail -18 "$ROOT/logs/upstream-tests.log"

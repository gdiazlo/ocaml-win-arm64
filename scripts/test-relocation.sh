#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
unset OCAMLLIB CAMLLIB OCAMLTOP_INCLUDE_PATH
mkdir -p 'dist/relocation test'
rm -rf -- 'dist/relocation test/ocaml-5.5.1-arm64-windows'
tar -xf dist/ocaml-5.5.1-arm64-windows-bin.tar.gz -C 'dist/relocation test'
PREFIX="$ROOT/dist/relocation test/ocaml-5.5.1-arm64-windows"
"$PREFIX/bin/ocamlc.exe" -where
"$PREFIX/bin/ocamlopt.exe" -version
"$PREFIX/bin/ocamlopt.exe" -thread -I +unix -I +threads unix.cmxa threads.cmxa \
  tests/compiler_smoke.ml -o 'dist/relocation test/smoke.exe'
'dist/relocation test/smoke.exe'
"$PREFIX/bin/ocamlc.exe" -custom -thread -I +unix -I +threads unix.cma threads.cma \
  tests/compiler_smoke.ml -o 'dist/relocation test/smoke.bc.exe'
'dist/relocation test/smoke.bc.exe'
"$PREFIX/bin/ocaml.exe" tests/unicode_smoke.ml
"$PREFIX/bin/ocamlopt.exe" -I +unix unix.cmxa tests/socket_timeout.ml \
  -o 'dist/relocation test/timeout.exe'
'dist/relocation test/timeout.exe'
printf 'PASS relocated compiler bundle, including paths with spaces\n'

#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
DEST='dist/dynamic relocation test'
rm -rf -- "$DEST"
mkdir -p "$DEST/work"
tar -xf dist/ocaml-5.5.1-arm64-windows-dynlink-bin.tar.gz -C "$DEST"
PREFIX="$ROOT/$DEST/ocaml-5.5.1-arm64-windows-dynlink"
export PATH="$PREFIX/bin:$PATH"
unset OPAM_SWITCH_PREFIX OCAMLLIB CAMLLIB CAML_LD_LIBRARY_PATH OCAMLTOP_INCLUDE_PATH FLEXDIR
cp tests/compiler_smoke.ml "$DEST/work/"
cp tests/ffi/{ffi_smoke.ml,ffi_stubs.c} "$DEST/work/"
cp tests/dynlink/{shared,plugin,host}.ml "$DEST/work/"
cd "$DEST/work"
ocamlopt.exe -where
ocamlc.exe -thread -I +unix -I +threads unix.cma threads.cma compiler_smoke.ml -o 'compiler byte.exe'
ocamlopt.exe -thread -I +unix -I +threads unix.cmxa threads.cmxa compiler_smoke.ml -o 'compiler native.exe'
'./compiler byte.exe'
'./compiler native.exe'
ocamlc.exe -c ffi_stubs.c
ocamlmklib.exe -o ffi ffi_stubs.o
ocamlc.exe -I . -dllib -lffi ffi_smoke.ml -o 'ffi byte.exe'
'./ffi byte.exe'
ocamlopt.exe -g -c shared.ml
ocamlopt.exe -g -c plugin.ml
ocamlopt.exe -g -shared -o plugin.cmxs plugin.cmx -ccopt -L. -cclib -lffi
ocamlopt.exe -g -linkall -I +dynlink dynlink.cmxa shared.cmx host.ml -o host.exe
cp plugin.cmxs 'plugin-λ-東京.cmxs'
./host.exe './plugin-λ-東京.cmxs'
printf 'PASS relocated dynamic compiler: spaces, ordinary bytecode C stubs, native plugin with UTF-8 filename.\n'

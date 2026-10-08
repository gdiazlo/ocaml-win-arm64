#!/usr/bin/env bash
# Ordinary bytecode (no -custom), native programs, and a native DLL plugin.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
export PATH="$ROOT/local-dynamic/bin:$ROOT/local-dynamic/flexdll:$PATH"
unset OCAMLLIB CAMLLIB CAML_LD_LIBRARY_PATH OCAMLTOP_INCLUDE_PATH
mkdir -p tests/dynamic
cp tests/{compiler_smoke,socket_timeout,unicode_smoke}.ml tests/dynamic/
(
  cd tests/dynamic
  ocamlc.exe -thread -I +unix -I +threads unix.cma threads.cma compiler_smoke.ml -o compiler.byte.exe
  ocamlopt.exe -thread -I +unix -I +threads unix.cmxa threads.cmxa compiler_smoke.ml -o compiler.exe
  ./compiler.byte.exe
  ./compiler.exe
  for compiler in ocamlc ocamlopt; do
    library=unix.cma
    if [[ $compiler == ocamlopt ]]; then library=unix.cmxa; fi
    "$compiler.exe" -I +unix "$library" socket_timeout.ml -o "timeout-$compiler.exe"
    "./timeout-$compiler.exe"
  done
  cp ../ffi/{ffi_smoke.ml,ffi_stubs.c} .
  ocamlc.exe -c ffi_stubs.c
  ocamlmklib.exe -o ffi ffi_stubs.o
  ocamlc.exe -I . -dllib -lffi ffi_smoke.ml -o ffi.byte.exe
  ./ffi.byte.exe
  ocamlopt.exe -I . -cclib -lffi ffi_smoke.ml -o ffi.exe
  ./ffi.exe
)
ocaml.exe tests/dynamic/unicode_smoke.ml
(
  cd tests/dynlink
  ocamlopt.exe -g -c shared.ml
  ocamlopt.exe -g -c plugin.ml
  ocamlopt.exe -g -shared -o plugin.cmxs plugin.cmx -ccopt -L../dynamic -cclib -lffi
  ocamlopt.exe -g -linkall -I +dynlink dynlink.cmxa shared.cmx host.ml -o host.exe
  ./host.exe ./plugin.cmxs
  file host.exe plugin.cmxs
)
(
  # A packed unit is an llvm-lib archive on this target; its members must still
  # be linked into the plugin and their frametables/roots found by Dynlink.
  cd tests/dynlink-pack
  ocamlopt.exe -c pack_host.ml
  ocamlopt.exe -for-pack P -c a.ml
  ocamlopt.exe -for-pack P -c b.ml
  ocamlopt.exe -pack -o p.cmx a.cmx b.cmx
  ocamlopt.exe -c pack_plugin.ml
  ocamlopt.exe -shared -o pack_plugin.cmxs p.cmx pack_plugin.cmx
  ocamlopt.exe -linkall -I +dynlink dynlink.cmxa pack_host.cmx pack_main.ml -o pack_main.exe
  ./pack_main.exe ./pack_plugin.cmxs
)
# Manual binding builds, separate from the preserved static opam switch.
# SQLite's C stub object comes from its existing validated ARM64 static archive;
# the OCaml wrapper is rebuilt. SSL's OCaml and C sources are rebuilt unmodified.
mkdir -p tests/dynamic/libraries
chmod -R u+w tests/dynamic/libraries
cp opam-root/windows-arm64/lib/sqlite3/sqlite3.{ml,mli} tests/dynamic/libraries/
cp sources/ssl/src/ssl.{ml,mli} sources/ssl/src/ssl_stubs.c tests/dynamic/libraries/
cp tests/libraries/{sqlite,ssl}_smoke.ml tests/dynamic/libraries/
(
  cd tests/dynamic/libraries
  # Old manual output names must not shadow the system -lsqlite3/-lssl.
  rm -f libsqlite3.a libssl.a dllsqlite3.dll dllssl.dll
  llvm-ar x ../../../opam-root/windows-arm64/lib/sqlite3/libsqlite3_stubs.a
  ocamlc.exe -c sqlite3.mli
  ocamlc.exe -c sqlite3.ml
  ocamlmklib.exe -o sqlite3 -oc sqlite3_stubs sqlite3.cmo sqlite3_stubs.o -lsqlite3
  ocamlc.exe -I +unix -c ssl.mli
  ocamlc.exe -I +unix -c ssl.ml
  ocamlc.exe -ccopt -O2 -c ssl_stubs.c
  ocamlmklib.exe -o ssl -oc ssl_stubs ssl.cmo ssl_stubs.o -lssl -lcrypto -lws2_32 -lgdi32 -lcrypt32
  ocamlc.exe -I . sqlite3.cma sqlite_smoke.ml -o sqlite.byte.exe
  ./sqlite.byte.exe
  ocamlc.exe -thread -I . -I +unix -I +threads unix.cma threads.cma ssl.cma ssl_smoke.ml -o ssl.byte.exe
)
mkdir -p tests/libraries/fixtures
MSYS2_ARG_CONV_EXCL='*' openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 2 \
  -subj /CN=localhost -addext subjectAltName=DNS:localhost \
  -keyout tests/libraries/fixtures/key.pem -out tests/libraries/fixtures/cert.pem \
  > logs/tls-fixture-generation.log 2>&1
export CAML_LD_LIBRARY_PATH="$(cygpath -am tests/dynamic/libraries)"
tests/dynamic/libraries/ssl.byte.exe tests/libraries/fixtures/cert.pem tests/libraries/fixtures/key.pem
printf 'PASS dynamic compiler, C stubs, native plugin, SQLite and SSL regressions.\n'

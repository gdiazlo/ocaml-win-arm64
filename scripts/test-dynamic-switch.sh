#!/usr/bin/env bash
# Source-built dynamic opam switch: normal Dune bytecode and findlib #require.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
export OPAMROOT="$ROOT/opam-root" DUNE_CACHE=disabled
unset OCAMLLIB CAMLLIB CAML_LD_LIBRARY_PATH OCAMLTOP_INCLUDE_PATH FLEXDIR
SWITCH=${1:-windows-arm64-dynlink}
OPAM="$ROOT/local/bin/opam.exe"
run() { "$OPAM" exec --switch="$SWITCH" -- "$@"; }
PREFIX="$ROOT/opam-root/$SWITCH"
STAGE=tests/dynamic-switch
mkdir -p logs "$STAGE/compiler" "$STAGE/pack"
run ocamlopt.exe -config
run ocamlfind.exe printconf
cp tests/{compiler_smoke,socket_timeout}.ml "$STAGE/compiler/"
cp tests/pack/{a,b,main}.ml "$STAGE/pack/"
cp tests/ffi/{ffi_smoke.ml,ffi_stubs.c} "$STAGE/ffi/"
cp tests/libraries/{sqlite,ssl,eio}_smoke.ml "$STAGE/libraries/"
(
  cd "$STAGE/compiler"
  run ocamlc.exe -thread -I +unix -I +threads unix.cma threads.cma compiler_smoke.ml -o compiler.byte.exe
  run ocamlopt.exe -thread -I +unix -I +threads unix.cmxa threads.cmxa compiler_smoke.ml -o compiler.exe
  run ./compiler.byte.exe
  run ./compiler.exe
  for compiler in ocamlc ocamlopt; do
    library=unix.cma
    if [[ $compiler == ocamlopt ]]; then library=unix.cmxa; fi
    run "$compiler.exe" -I +unix "$library" socket_timeout.ml -o "timeout-$compiler.exe"
    run "./timeout-$compiler.exe"
  done
)
# The dynamic toplevel does not preload Unix like the old static toplevel.
run ocaml.exe -noinit -I +unix unix.cma tests/unicode_smoke.ml
(
  cd "$STAGE/pack"
  run ocamlopt.exe -for-pack P -c a.ml
  run ocamlopt.exe -for-pack P -c b.ml
  run ocamlopt.exe -pack -o p.cmx a.cmx b.cmx
  run ocamlopt.exe -o pack.exe p.cmx main.ml
  run ./pack.exe
  run ocamlopt.exe -a -o packed.cmxa p.cmx
  run ocamlopt.exe -o pack-library.exe packed.cmxa main.ml
  run ./pack-library.exe
)
run dune.exe clean --root "$STAGE"
run dune.exe build --root "$STAGE" -j 2
mkdir -p tests/libraries/fixtures
MSYS2_ARG_CONV_EXCL='*' openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 2 \
  -subj /CN=localhost -addext subjectAltName=DNS:localhost \
  -keyout tests/libraries/fixtures/key.pem -out tests/libraries/fixtures/cert.pem \
  > logs/tls-fixture-generation.log 2>&1
STUBS="$(cygpath -am "$ROOT/$STAGE/_build/default/ffi");$(cygpath -am "$PREFIX/lib/stublibs")"
for name in ffi/ffi_smoke libraries/sqlite_smoke libraries/ssl_smoke libraries/eio_smoke; do
  args=()
  if [[ $name == libraries/ssl_smoke ]]; then
    args=(tests/libraries/fixtures/cert.pem tests/libraries/fixtures/key.pem)
  fi
  run "$STAGE/_build/default/$name.exe" "${args[@]}"
  run env "CAML_LD_LIBRARY_PATH=$STUBS" ocamlrun.exe "$STAGE/_build/default/$name.bc" "${args[@]}"
done
run ocaml.exe -noinit "$STAGE/interactive.ml" tests/libraries/fixtures/cert.pem tests/libraries/fixtures/key.pem \
  > logs/dynamic-interactive.log 2>&1
if grep -Eq 'Error:|Exception:|Cannot load|required.*not found' logs/dynamic-interactive.log; then
  tail -60 logs/dynamic-interactive.log
  exit 1
fi
for marker in 'PASS SQLite' 'PASS SSL' 'PASS Eio Windows: asynchronous localhost TCP' 'PASS interactive #require'; do
  grep -F "$marker" logs/dynamic-interactive.log
done
for binary in "$PREFIX/bin/"{ocamlrun,ocamlc,ocamlopt,flexlink}.exe "$PREFIX/bin/libzstd.dll" \
  "$PREFIX/lib/stublibs/"{dllsqlite3_stubs,dllssl_stubs,dlleio_windows_stubs}.dll \
  "$STAGE/_build/default/ffi/ffi_smoke.exe" "$STAGE/_build/default/ffi/dllffi_support_stubs.dll" \
  "$STAGE/_build/default/libraries/"{sqlite,ssl,eio}_smoke.exe; do
  info=$(file "$binary")
  echo "$info"
  [[ $info == *ARM64* ]] || { echo "Not ARM64: $binary" >&2; exit 1; }
done
printf 'PASS fresh dynamic switch: compiler, packing, Dune native/ordinary bytecode, interactive bindings, ARM64 architecture.\n'

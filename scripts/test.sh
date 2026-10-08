#!/usr/bin/env bash
# Run through scripts/msys.sh. Fails immediately on a build/test failure.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/scripts/common.sh"
cd "$ROOT"
export PATH="$ROOT/local/bin:$PATH" DUNE_CACHE=disabled
OPAM="$ROOT/local/bin/opam.exe"
SWITCH=${1:-windows-arm64}
run() { "$OPAM" exec --switch="$SWITCH" -- "$@"; }
mkdir -p logs
exec > >(tee logs/validation.log) 2>&1
run ocamlc.exe -config
"$OPAM" --version
run ocamlfind.exe printconf
run ocamlc.exe -custom -thread -I +unix -I +threads unix.cma threads.cma \
  tests/compiler_smoke.ml -o tests/compiler_smoke.bc.exe
run ocamlopt.exe -thread -I +unix -I +threads unix.cmxa threads.cmxa \
  tests/compiler_smoke.ml -o tests/compiler_smoke.exe
run tests/compiler_smoke.bc.exe
run tests/compiler_smoke.exe
run ocaml.exe tests/unicode_smoke.ml
run ocamlc.exe -custom -I +unix unix.cma tests/socket_timeout.ml -o tests/socket_timeout.bc.exe
run ocamlopt.exe -I +unix unix.cmxa tests/socket_timeout.ml -o tests/socket_timeout.exe
run tests/socket_timeout.bc.exe
run tests/socket_timeout.exe
(
  cd tests/pack
  run ocamlopt.exe -for-pack P -c a.ml
  run ocamlopt.exe -for-pack P -c b.ml
  run ocamlopt.exe -pack -o p.cmx a.cmx b.cmx
  run ocamlopt.exe -o pack-smoke.exe p.cmx main.ml
  run ./pack-smoke.exe
  run ocamlopt.exe -a -o packed.cmxa p.cmx
  run ocamlopt.exe -o pack-library-smoke.exe packed.cmxa main.ml
  run ./pack-library-smoke.exe
)
run dune clean --root tests/ffi
run dune build --root tests/ffi -j 2
run tests/ffi/_build/default/ffi_smoke.exe
run tests/ffi/_build/default/ffi_smoke.bc.exe
run dune clean --root tests/libraries
run dune build --root tests/libraries -j 2
# Test fixtures only: a fresh, short-lived localhost certificate and key.
mkdir -p tests/libraries/fixtures
MSYS2_ARG_CONV_EXCL='*' openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 2 \
  -subj /CN=localhost -addext subjectAltName=DNS:localhost \
  -keyout tests/libraries/fixtures/key.pem -out tests/libraries/fixtures/cert.pem \
  > logs/tls-fixture-generation.log 2>&1
for suffix in exe bc.exe; do
  run "tests/libraries/_build/default/sqlite_smoke.$suffix"
  run "tests/libraries/_build/default/ssl_smoke.$suffix" \
    tests/libraries/fixtures/cert.pem tests/libraries/fixtures/key.pem
  run "tests/libraries/_build/default/eio_smoke.$suffix"
done
printf '\nExecutable architecture checks:\n'
for exe in local/bin/{ocamlrun,ocamlc,ocamlopt,opam,opam-installer}.exe \
  tests/compiler_smoke{,.bc}.exe tests/ffi/_build/default/ffi_smoke{,.bc}.exe \
  tests/libraries/_build/default/{sqlite,ssl,eio}_smoke{,.bc}.exe; do
  info=$(file "$exe")
  echo "$info"
  [[ "$info" == *ARM64* ]] || { echo "Not ARM64: $exe" >&2; exit 1; }
done
printf '\nAll local validation tests passed.\n'
